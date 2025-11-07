"""Chat interface using Gemini with file search."""

from google import genai
from google.genai import types
from rich.console import Console
from rich.markdown import Markdown
from rich.panel import Panel


class KnowledgeBaseChat:
    """Interactive chat interface for querying the knowledge base."""

    def __init__(self, api_key: str, model: str = "gemini-2.5-flash"):
        """Initialize the chat interface.

        Args:
            api_key: Google Gemini API key
            model: Gemini model to use (must be gemini-2.5-flash or gemini-2.5-pro for file_search)
        """
        self.client = genai.Client(api_key=api_key)
        self.model = model
        self.console = Console()

    def query(
        self,
        question: str,
        file_search_store_name: str,
        show_sources: bool = True,
    ) -> str | None:
        """Query the knowledge base.

        Args:
            question: User's question
            file_search_store_name: File search store resource name
            show_sources: Whether to display source information

        Returns:
            Response text, or None on error
        """
        try:
            # Query with file search
            response = self.client.models.generate_content(
                model=self.model,
                contents=question,
                config=types.GenerateContentConfig(
                    tools=[
                        types.Tool(
                            file_search=types.FileSearch(
                                file_search_store_names=[file_search_store_name]
                            )
                        )
                    ]
                ),
            )

            if not response or not response.text:
                return None

            # Display response
            self.console.print("\n")
            self.console.print(Markdown(response.text))

            # Display sources if requested
            if show_sources and response.candidates:
                self._display_sources(response)

            return response.text

        except Exception as e:
            self.console.print(f"\n❌ Error querying knowledge base: {e!s}", style="red")
            return None

    def interactive_chat(self, file_search_store_name: str, playlist_title: str | None = None):
        """Start an interactive chat session.

        Args:
            file_search_store_name: File search store resource name
            playlist_title: Optional playlist title for display
        """
        title = (
            f"Knowledge Base Chat: {playlist_title}" if playlist_title else "Knowledge Base Chat"
        )

        self.console.print(
            Panel(
                "[bold cyan]Ask questions about the videos in the knowledge base[/]\n"
                "[dim]Type 'exit', 'quit', or 'q' to end the session[/]",
                title=title,
                border_style="cyan",
            )
        )

        while True:
            try:
                # Get user input
                self.console.print("\n[bold cyan]You:[/] ", end="")
                question = input().strip()

                if not question:
                    continue

                # Check for exit commands
                if question.lower() in ["exit", "quit", "q"]:
                    self.console.print("\n[dim]Goodbye![/]")
                    break

                # Query the knowledge base
                self.console.print("\n[bold green]Assistant:[/]")
                self.query(question, file_search_store_name)

            except KeyboardInterrupt:
                self.console.print("\n\n[dim]Goodbye![/]")
                break
            except EOFError:
                break

    def _display_sources(self, response):
        """Display source information from the response.

        Args:
            response: Gemini API response
        """
        try:
            candidate = response.candidates[0]

            if hasattr(candidate, "grounding_metadata") and candidate.grounding_metadata:
                grounding = candidate.grounding_metadata

                # Display retrieval queries if available
                if hasattr(grounding, "retrieval_queries") and grounding.retrieval_queries:
                    self.console.print("\n[dim]📚 Retrieved from:[/]")
                    for query in grounding.retrieval_queries:
                        self.console.print(f"  [dim]• {query}[/]")

                # Display grounding chunks if available
                if hasattr(grounding, "grounding_chunks") and grounding.grounding_chunks:
                    self.console.print("\n[dim]📄 Sources:[/]")
                    for i, chunk in enumerate(grounding.grounding_chunks[:3], 1):  # Show top 3
                        if hasattr(chunk, "retrieved_context"):
                            context = chunk.retrieved_context
                            if hasattr(context, "title"):
                                self.console.print(f"  [dim]{i}. {context.title}[/]")

        except Exception:
            # Silently ignore source display errors
            pass
