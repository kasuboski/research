"""Tests for Gemini file upload functionality."""

import tempfile
from pathlib import Path
from unittest.mock import MagicMock

import pytest
from google import genai

from youtube_knowledge.uploader import GeminiUploader


class TestGeminiUploader:
    """Tests for GeminiUploader class."""

    def test_init(self, mocker, mock_gemini_api_key):
        """Test GeminiUploader initialization."""
        mock_client_class = mocker.patch.object(genai, "Client")

        uploader = GeminiUploader(api_key=mock_gemini_api_key)

        mock_client_class.assert_called_once_with(api_key=mock_gemini_api_key)
        assert uploader.client is not None

    def test_get_or_create_file_search_store_existing(self, mocker, mock_gemini_api_key):
        """Test getting an existing file search store."""
        # Create mock store
        mock_store = MagicMock()
        mock_store.name = "stores/test-store-123"
        mock_store.display_name = "Test Store"

        # Mock the client's file_search_stores.list method
        mock_client = MagicMock()
        mock_client.file_search_stores.list.return_value = [mock_store]

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader.get_or_create_file_search_store("Test Store")

        assert result == "stores/test-store-123"
        mock_client.file_search_stores.list.assert_called_once()
        mock_client.file_search_stores.create.assert_not_called()

    def test_get_or_create_file_search_store_new(self, mocker, mock_gemini_api_key):
        """Test creating a new file search store."""
        # Mock store to be created
        mock_new_store = MagicMock()
        mock_new_store.name = "stores/new-store-456"

        # Mock the client
        mock_client = MagicMock()
        mock_client.file_search_stores.list.return_value = []  # No existing stores
        mock_client.file_search_stores.create.return_value = mock_new_store

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader.get_or_create_file_search_store("New Store")

        assert result == "stores/new-store-456"
        mock_client.file_search_stores.list.assert_called_once()
        mock_client.file_search_stores.create.assert_called_once_with(
            config={"display_name": "New Store"}
        )

    def test_get_or_create_file_search_store_exception(self, mocker, mock_gemini_api_key):
        """Test handling of exception when creating file search store."""
        mock_client = MagicMock()
        mock_client.file_search_stores.list.side_effect = Exception("API error")

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)

        with pytest.raises(Exception) as exc_info:
            uploader.get_or_create_file_search_store("Test Store")

        assert "Failed to get or create file search store" in str(exc_info.value)

    def test_check_existing_file_found(self, mocker, mock_gemini_api_key):
        """Test checking for an existing file that exists."""
        # Create mock files
        mock_file1 = MagicMock()
        mock_file1.name = "files/file-123"
        mock_file1.display_name = "existing.md"

        mock_file2 = MagicMock()
        mock_file2.name = "files/file-456"
        mock_file2.display_name = "other.md"

        mock_client = MagicMock()
        mock_client.files.list.return_value = [mock_file1, mock_file2]

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader._check_existing_file("existing.md")

        assert result == "files/file-123"

    def test_check_existing_file_not_found(self, mocker, mock_gemini_api_key):
        """Test checking for a file that doesn't exist."""
        mock_file = MagicMock()
        mock_file.display_name = "other.md"

        mock_client = MagicMock()
        mock_client.files.list.return_value = [mock_file]

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader._check_existing_file("nonexistent.md")

        assert result is None

    def test_check_existing_file_exception(self, mocker, mock_gemini_api_key):
        """Test handling of exception when checking for existing file."""
        mock_client = MagicMock()
        mock_client.files.list.side_effect = Exception("List error")

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader._check_existing_file("test.md")

        # Should return None on exception
        assert result is None

    def test_upload_document_success(self, mocker, mock_gemini_api_key):
        """Test successful document upload."""
        # Mock operation that's done with response containing document name
        mock_response = MagicMock()
        mock_response.document_name = "fileSearchStores/store-123/documents/doc-456"

        mock_operation = MagicMock()
        mock_operation.name = "operations/upload-123"
        mock_operation.done = True
        mock_operation.response = mock_response

        mock_client = MagicMock()
        mock_client.file_search_stores.upload_to_file_search_store.return_value = mock_operation
        mock_client.operations.get.return_value = mock_operation
        mock_client.files.list.return_value = []  # No existing files

        mocker.patch.object(genai, "Client", return_value=mock_client)

        # Mock Path.unlink to avoid file system operations
        mocker.patch.object(Path, "unlink")

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader.upload_document(
            content="# Test Content",
            display_name="test.md",
            store_name="stores/test-123",
            check_existing=False,
        )

        assert result == "fileSearchStores/store-123/documents/doc-456"
        mock_client.file_search_stores.upload_to_file_search_store.assert_called_once()

    def test_upload_document_existing_file(self, mocker, mock_gemini_api_key):
        """Test upload when file already exists."""
        mock_file = MagicMock()
        mock_file.name = "files/existing-123"
        mock_file.display_name = "existing.md"

        mock_client = MagicMock()
        mock_client.files.list.return_value = [mock_file]

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader.upload_document(
            content="# Test Content",
            display_name="existing.md",
            store_name="stores/test-123",
            check_existing=True,
        )

        # Should return existing file name without uploading
        assert result == "files/existing-123"
        mock_client.file_search_stores.upload_to_file_search_store.assert_not_called()

    def test_upload_document_wait_for_indexing(self, mocker, mock_gemini_api_key):
        """Test that upload waits for indexing to complete."""
        # Mock operations that transition from not done to done
        mock_operation_pending = MagicMock()
        mock_operation_pending.name = "operations/upload-123"
        mock_operation_pending.done = False

        mock_response = MagicMock()
        mock_response.document_name = "fileSearchStores/store-123/documents/doc-456"

        mock_operation_done = MagicMock()
        mock_operation_done.name = "operations/upload-123"
        mock_operation_done.done = True
        mock_operation_done.response = mock_response

        mock_client = MagicMock()
        mock_client.file_search_stores.upload_to_file_search_store.return_value = (
            mock_operation_pending
        )
        # First call returns pending, second call returns done
        mock_client.operations.get.side_effect = [
            mock_operation_pending,
            mock_operation_done,
        ]
        mock_client.files.list.return_value = []

        mocker.patch.object(genai, "Client", return_value=mock_client)
        mocker.patch.object(Path, "unlink")

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader.upload_document(
            content="# Test Content",
            display_name="test.md",
            store_name="stores/test-123",
            check_existing=False,
        )

        assert result == "fileSearchStores/store-123/documents/doc-456"
        # Should have checked status twice (once pending, once done)
        assert mock_client.operations.get.call_count == 2

    def test_upload_document_exception(self, mocker, mock_gemini_api_key):
        """Test handling of exception during upload."""
        mock_client = MagicMock()
        mock_client.file_search_stores.upload_to_file_search_store.side_effect = Exception(
            "Upload failed"
        )
        mock_client.files.list.return_value = []

        mocker.patch.object(genai, "Client", return_value=mock_client)
        mocker.patch.object(Path, "unlink")

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        result = uploader.upload_document(
            content="# Test Content",
            display_name="test.md",
            store_name="stores/test-123",
            check_existing=False,
        )

        assert result is None

    def test_list_files(self, mocker, mock_gemini_api_key):
        """Test listing all uploaded files."""
        mock_file1 = MagicMock()
        mock_file1.name = "files/file-123"
        mock_file1.display_name = "test1.md"

        mock_file2 = MagicMock()
        mock_file2.name = "files/file-456"
        mock_file2.display_name = "test2.md"

        mock_client = MagicMock()
        mock_client.files.list.return_value = [mock_file1, mock_file2]

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        files = uploader.list_files()

        assert len(files) == 2
        assert files[0] == ("files/file-123", "test1.md")
        assert files[1] == ("files/file-456", "test2.md")

    def test_list_files_exception(self, mocker, mock_gemini_api_key):
        """Test handling of exception when listing files."""
        mock_client = MagicMock()
        mock_client.files.list.side_effect = Exception("List error")

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        files = uploader.list_files()

        assert files == []

    def test_get_file_search_stores(self, mocker, mock_gemini_api_key):
        """Test listing all file search stores."""
        mock_store1 = MagicMock()
        mock_store1.name = "stores/store-123"
        mock_store1.display_name = "Store 1"

        mock_store2 = MagicMock()
        mock_store2.name = "stores/store-456"
        mock_store2.display_name = "Store 2"

        mock_client = MagicMock()
        mock_client.file_search_stores.list.return_value = [mock_store1, mock_store2]

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        stores = uploader.get_file_search_stores()

        assert len(stores) == 2
        assert stores[0] == ("stores/store-123", "Store 1")
        assert stores[1] == ("stores/store-456", "Store 2")

    def test_get_file_search_stores_exception(self, mocker, mock_gemini_api_key):
        """Test handling of exception when listing stores."""
        mock_client = MagicMock()
        mock_client.file_search_stores.list.side_effect = Exception("List error")

        mocker.patch.object(genai, "Client", return_value=mock_client)

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        stores = uploader.get_file_search_stores()

        assert stores == []

    def test_upload_document_creates_temp_file(self, mocker, mock_gemini_api_key):
        """Test that upload creates a temporary file with correct content."""
        mock_operation = MagicMock()
        mock_operation.name = "operations/upload-123"
        mock_operation.done = True

        mock_client = MagicMock()
        mock_client.file_search_stores.upload_to_file_search_store.return_value = mock_operation
        mock_client.operations.get.return_value = mock_operation
        mock_client.files.list.return_value = []

        mocker.patch.object(genai, "Client", return_value=mock_client)

        # Track temporary file creation
        original_tempfile = tempfile.NamedTemporaryFile
        temp_files_created = []

        def track_tempfile(*args, **kwargs):
            temp_file = original_tempfile(*args, **kwargs)
            temp_files_created.append(temp_file.name)
            return temp_file

        mocker.patch("tempfile.NamedTemporaryFile", side_effect=track_tempfile)
        mock_unlink = mocker.patch.object(Path, "unlink")

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        uploader.upload_document(
            content="# Test Content\n\nThis is a test.",
            display_name="test.md",
            store_name="stores/test-123",
            check_existing=False,
        )

        # Verify temp file was created and cleaned up
        assert len(temp_files_created) == 1
        mock_unlink.assert_called_once()

    def test_upload_document_chunking_config(self, mocker, mock_gemini_api_key):
        """Test that upload includes correct chunking configuration."""
        mock_operation = MagicMock()
        mock_operation.name = "operations/upload-123"
        mock_operation.done = True

        mock_client = MagicMock()
        mock_client.file_search_stores.upload_to_file_search_store.return_value = mock_operation
        mock_client.operations.get.return_value = mock_operation
        mock_client.files.list.return_value = []

        mocker.patch.object(genai, "Client", return_value=mock_client)
        mocker.patch.object(Path, "unlink")

        uploader = GeminiUploader(api_key=mock_gemini_api_key)
        uploader.upload_document(
            content="# Test Content",
            display_name="test.md",
            store_name="stores/test-123",
            check_existing=False,
        )

        # Get the config that was passed to upload
        call_kwargs = mock_client.file_search_stores.upload_to_file_search_store.call_args[1]
        config = call_kwargs["config"]

        assert config["display_name"] == "test.md"
        assert "chunking_config" in config
        assert "white_space_config" in config["chunking_config"]
        assert config["chunking_config"]["white_space_config"]["max_tokens_per_chunk"] == 500
        assert config["chunking_config"]["white_space_config"]["max_overlap_tokens"] == 50
