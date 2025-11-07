"""Command-line interface for YouTube Knowledge Base."""

import os
import sys

import click
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table

from .chat import KnowledgeBaseChat
from .models import ProcessedVideo
from .playlist import PlaylistFetcher
from .state import StateManager
from .transcript import TranscriptRetriever
from .transform import TranscriptTransformer
from .uploader import GeminiUploader


console = Console()


def get_api_key() -> str:
    """Get Gemini API key from environment."""
    api_key = os.environ.get("GOOGLE_API_KEY") or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        console.print(
            "[red]Error: GOOGLE_API_KEY or GEMINI_API_KEY environment variable not set[/]"
        )
        sys.exit(1)
    return api_key


def _process_single_video(
    video,
    state: StateManager,
    state_obj,
    transcript_retriever: TranscriptRetriever,
    transformer: TranscriptTransformer,
    uploader: GeminiUploader,
    file_search_store: str,
) -> tuple[bool, str]:
    """Process a single video and return (success, status).

    Returns:
        Tuple of (success: bool, status: str) where status is "processed", "failed", or "skipped"
    """
    # Get transcript
    transcript = transcript_retriever.get_transcript(video.video_id)
    if not transcript:
        error = "Failed to retrieve transcript"
        state_obj.add_failed(video.video_id, error)
        state.save(state_obj)
        return False, "failed"

    # Format transcript
    formatted_transcript = transcript_retriever.format_transcript(transcript)
    console.print(f"  📝 Retrieved transcript ({len(transcript)} segments)")

    # Transform transcript
    transformed = transformer.transform(video, transcript, formatted_transcript)
    if not transformed:
        error = "Failed to transform transcript"
        state_obj.add_failed(video.video_id, error)
        state.save(state_obj)
        return False, "failed"

    console.print(f"  🤖 Transformed transcript ({len(transformed)} chars)")

    # Upload to Gemini
    display_name = f"youtube-{video.video_id}"
    file_name = uploader.upload_document(
        content=transformed,
        display_name=display_name,
        store_name=file_search_store,
    )

    if file_name:
        # Record success
        processed_video = ProcessedVideo.create(
            video_id=video.video_id,
            title=video.title,
            gemini_file_name=display_name,
            transcript_length=len(formatted_transcript),
            transformed_length=len(transformed),
        )
        state_obj.add_processed(processed_video)
        state.save(state_obj)
        return True, "processed"

    # Record failure
    error = "Failed to upload to Gemini"
    state_obj.add_failed(video.video_id, error)
    state.save(state_obj)
    return False, "failed"


def _print_summary(processed_count: int, skipped_count: int, failed_count: int, playlist_id: str):
    """Print processing summary."""
    console.print("\n[bold green]Processing Complete![/]")
    console.print(f"  ✅ Processed: {processed_count}")
    console.print(f"  ⏭️  Skipped: {skipped_count}")
    if failed_count > 0:
        console.print(f"  ❌ Failed: {failed_count}")

    console.print("\n[cyan]To chat with this knowledge base, run:[/]")
    console.print(f"[bold]yt_knowledge chat --playlist-id {playlist_id}[/]")


@click.group()
@click.version_option(version="0.1.0")
def main():
    """Transform YouTube playlists into Gemini knowledge bases."""
    pass


@main.command()
@click.option(
    "--playlist-id",
    "-p",
    required=True,
    help="YouTube playlist ID or URL",
)
@click.option(
    "--store-name",
    "-s",
    help="Custom file search store name (default: playlist title)",
)
@click.option(
    "--skip-existing/--reprocess",
    default=True,
    help="Skip already processed videos (default: True)",
)
@click.option(
    "--languages",
    "-l",
    default="en",
    help="Comma-separated list of preferred transcript languages (default: en)",
)
def process(playlist_id: str, store_name: str, skip_existing: bool, languages: str):
    """Process a YouTube playlist and upload to Gemini knowledge base.

    Example:
        yt_knowledge process --playlist-id PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf
    """
    api_key = get_api_key()

    # Initialize components
    state_manager = StateManager()
    playlist_fetcher = PlaylistFetcher()
    transcript_retriever = TranscriptRetriever(languages=languages.split(","))
    transformer = TranscriptTransformer(api_key=api_key)
    uploader = GeminiUploader(api_key=api_key)

    try:
        # Fetch playlist videos
        console.print(f"\n[bold cyan]Fetching playlist: {playlist_id}[/]")
        videos = playlist_fetcher.fetch_videos(playlist_id)

        if not videos:
            console.print("[red]No videos found in playlist[/]")
            return

        playlist_title = playlist_fetcher.get_playlist_title(playlist_id) or playlist_id
        console.print(f"[green]Found {len(videos)} videos in '{playlist_title}'[/]\n")

        # Determine store name
        if not store_name:
            store_name = f"youtube-{playlist_id}"

        # Get or create file search store
        file_search_store = uploader.get_or_create_file_search_store(store_name)

        # Load or create state
        state = state_manager.get_or_create(playlist_id, file_search_store)

        # Process each video
        processed_count = 0
        skipped_count = 0
        failed_count = 0

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:
            task = progress.add_task("Processing videos...", total=len(videos))

            for i, video in enumerate(videos, 1):
                progress.update(
                    task,
                    description=f"[{i}/{len(videos)}] {video.title[:50]}...",
                )

                # Skip if already processed
                if skip_existing and state.is_processed(video.video_id):
                    console.print(f"  ⏭️  Skipping (already processed): {video.title}")
                    skipped_count += 1
                    progress.advance(task)
                    continue

                console.print(f"\n[bold]Processing:[/] {video.title}")

                # Process the video
                success, _status = _process_single_video(
                    video,
                    state_manager,
                    state,
                    transcript_retriever,
                    transformer,
                    uploader,
                    file_search_store,
                )

                if success:
                    processed_count += 1
                else:
                    failed_count += 1

                progress.advance(task)

        # Summary
        _print_summary(processed_count, skipped_count, failed_count, playlist_id)

    except Exception as e:
        console.print(f"\n[red]Error: {e!s}[/]")
        sys.exit(1)


@main.command()
@click.option(
    "--playlist-id",
    "-p",
    help="Playlist ID to chat with (if not specified, lists available playlists)",
)
@click.option(
    "--query",
    "-q",
    help="Single query instead of interactive chat",
)
def chat(playlist_id: str, query: str):
    """Chat with a processed knowledge base.

    Example:
        yt_knowledge chat --playlist-id PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf
    """
    api_key = get_api_key()
    state_manager = StateManager()

    # If no playlist specified, list available playlists
    if not playlist_id:
        playlists = state_manager.list_playlists()
        if not playlists:
            console.print("[yellow]No processed playlists found.[/]")
            console.print("Run [bold]yt_knowledge process[/] first to process a playlist.")
            return

        console.print("\n[bold cyan]Available Knowledge Bases:[/]\n")
        table = Table(show_header=True, header_style="bold magenta")
        table.add_column("Playlist ID", style="cyan")
        table.add_column("Videos", justify="right")
        table.add_column("Last Updated")

        for playlist in playlists:
            table.add_row(
                playlist.playlist_id,
                str(len(playlist.processed_videos)),
                playlist.last_updated[:10],
            )

        console.print(table)
        console.print("\n[dim]Use: yt_knowledge chat --playlist-id <ID>[/]")
        return

    # Load playlist state
    state = state_manager.load(playlist_id)
    if not state:
        console.print(f"[red]No processed data found for playlist: {playlist_id}[/]")
        console.print("Run [bold]yt_knowledge process[/] first to process this playlist.")
        return

    if not state.processed_videos:
        console.print(f"[yellow]No successfully processed videos in playlist: {playlist_id}[/]")
        return

    # Initialize chat
    chat_interface = KnowledgeBaseChat(api_key=api_key)

    # Single query mode
    if query:
        chat_interface.query(query, state.file_search_store_name)
        return

    # Interactive chat mode
    playlist_fetcher = PlaylistFetcher()
    playlist_title = playlist_fetcher.get_playlist_title(playlist_id)
    chat_interface.interactive_chat(state.file_search_store_name, playlist_title)


@main.command()
def list():
    """List all processed playlists."""
    state_manager = StateManager()
    playlists = state_manager.list_playlists()

    if not playlists:
        console.print("[yellow]No processed playlists found.[/]")
        return

    console.print("\n[bold cyan]Processed Playlists:[/]\n")

    for playlist in playlists:
        console.print(f"[bold]Playlist ID:[/] {playlist.playlist_id}")
        console.print(f"  Store: {playlist.file_search_store_name}")
        console.print(f"  Videos: {len(playlist.processed_videos)} processed")
        if playlist.failed_videos:
            console.print(f"  Failed: {len(playlist.failed_videos)} videos")
        console.print(f"  Last Updated: {playlist.last_updated}")
        console.print()


if __name__ == "__main__":
    main()
