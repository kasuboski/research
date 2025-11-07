"""File upload to Gemini File Search with idempotency."""

import tempfile
import time
from pathlib import Path

from google import genai


class GeminiUploader:
    """Handles file uploads to Gemini File Search."""

    def __init__(self, api_key: str):
        """Initialize the Gemini uploader.

        Args:
            api_key: Google Gemini API key
        """
        self.client = genai.Client(api_key=api_key)

    def get_or_create_file_search_store(self, store_name: str) -> str:
        """Get existing file search store or create a new one.

        Args:
            store_name: Display name for the file search store

        Returns:
            File search store resource name
        """
        try:
            # List existing stores
            for store in self.client.file_search_stores.list():
                # FileSearchStore has display_name attribute directly
                if store.display_name == store_name:
                    print(f"  [i] Using existing file search store: {store_name}")
                    assert store.name, "Store name must not be None"
                    return store.name

            # Create new store if not found
            print(f"  ✨ Creating new file search store: {store_name}")
            store = self.client.file_search_stores.create(config={"display_name": store_name})
            assert store.name, "Created store must have a name"
            return store.name

        except Exception as e:
            raise Exception(f"Failed to get or create file search store: {e!s}") from e

    def upload_document(
        self,
        content: str,
        display_name: str,
        store_name: str,
        check_existing: bool = True,
    ) -> str | None:
        """Upload a document to Gemini File Search.

        Args:
            content: Document content (markdown)
            display_name: Deterministic display name for the file
            store_name: File search store resource name
            check_existing: Check if file already exists before uploading

        Returns:
            Uploaded file resource name, or None on error
        """
        try:
            # Check if file already exists
            if check_existing:
                existing = self._check_existing_file(display_name)
                if existing:
                    print(f"  ♻️  File already uploaded: {display_name}")
                    return existing

            # Write content to temporary file
            with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as tmp_file:
                tmp_file.write(content)
                tmp_path = tmp_file.name

            try:
                # Upload directly to file search store
                print(f"  📤 Uploading: {display_name}")
                operation = self.client.file_search_stores.upload_to_file_search_store(
                    file=tmp_path,
                    file_search_store_name=store_name,
                    config={
                        "display_name": display_name,
                        "mime_type": "text/markdown",
                        "chunking_config": {
                            "white_space_config": {
                                "max_tokens_per_chunk": 500,
                                "max_overlap_tokens": 50,
                            }
                        },
                    },
                )

                # Wait for indexing to complete
                print("  ⏳ Indexing...")
                while not operation.done:
                    time.sleep(2)
                    operation = self.client.operations.get(operation)

                # Extract document name from operation response
                # The response is an UploadToFileSearchStoreResponse object
                response = getattr(operation, "response", None)
                if response and hasattr(response, "document_name"):
                    document_name = response.document_name
                    if document_name:
                        print(f"  ✅ Successfully uploaded and indexed: {display_name}")
                        return document_name

                raise Exception("Operation completed but no document name in response")

            finally:
                # Clean up temporary file
                Path(tmp_path).unlink(missing_ok=True)

        except Exception as e:
            print(f"  ❌ Upload failed for {display_name}: {e!s}")
            return None

    def _check_existing_file(self, display_name: str) -> str | None:
        """Check if a file with the given display name already exists.

        Args:
            display_name: File display name to check

        Returns:
            File resource name if exists, None otherwise
        """
        try:
            # List files in the Files API
            for file in self.client.files.list():
                if file.display_name == display_name:
                    return file.name
            return None
        except Exception:
            # If listing fails, assume file doesn't exist
            return None

    def list_files(self) -> list[tuple[str, str]]:
        """List all uploaded files.

        Returns:
            List of (file_name, display_name) tuples
        """
        files = []
        try:
            for file in self.client.files.list():
                files.append((file.name, file.display_name))
        except Exception as e:
            print(f"Warning: Failed to list files: {e}")
        return files

    def get_file_search_stores(self) -> list[tuple[str, str]]:
        """List all file search stores.

        Returns:
            List of (store_name, display_name) tuples
        """
        stores = []
        try:
            for store in self.client.file_search_stores.list():
                # FileSearchStore has display_name attribute directly
                stores.append((store.name, store.display_name))
        except Exception as e:
            print(f"Warning: Failed to list file search stores: {e}")
        return stores
