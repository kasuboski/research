"""Data models for YouTube to Gemini knowledge base."""

from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class VideoInfo:
    """Information about a YouTube video."""

    video_id: str
    title: str
    url: str

    @classmethod
    def from_yt_dlp(cls, entry: dict) -> "VideoInfo":
        """Create VideoInfo from yt-dlp playlist entry."""
        video_id = entry.get("id", "")
        title = entry.get("title", "Unknown Title")
        url = entry.get("webpage_url", f"https://www.youtube.com/watch?v={video_id}")
        return cls(video_id=video_id, title=title, url=url)


@dataclass
class TranscriptEntry:
    """A single transcript entry with timing."""

    text: str
    start: float
    duration: float


@dataclass
class ProcessedVideo:
    """Record of a processed video."""

    video_id: str
    title: str
    processed_at: str
    gemini_file_name: str
    transcript_length: int
    transformed_length: int
    error: str | None = None

    @classmethod
    def create(
        cls,
        video_id: str,
        title: str,
        gemini_file_name: str,
        transcript_length: int = 0,
        transformed_length: int = 0,
        error: str | None = None,
    ) -> "ProcessedVideo":
        """Create a new ProcessedVideo record."""
        return cls(
            video_id=video_id,
            title=title,
            processed_at=datetime.utcnow().isoformat(),
            gemini_file_name=gemini_file_name,
            transcript_length=transcript_length,
            transformed_length=transformed_length,
            error=error,
        )


@dataclass
class PlaylistState:
    """State tracking for a processed playlist."""

    playlist_id: str
    file_search_store_name: str
    created_at: str
    last_updated: str
    processed_videos: dict[str, ProcessedVideo] = field(default_factory=dict)
    failed_videos: dict[str, str] = field(default_factory=dict)

    def is_processed(self, video_id: str) -> bool:
        """Check if a video has been successfully processed."""
        return video_id in self.processed_videos and not self.processed_videos[video_id].error

    def add_processed(self, video: ProcessedVideo) -> None:
        """Add a processed video to the state."""
        self.processed_videos[video.video_id] = video
        self.last_updated = datetime.utcnow().isoformat()
        if video.error and video.video_id in self.failed_videos:
            del self.failed_videos[video.video_id]

    def add_failed(self, video_id: str, error: str) -> None:
        """Add a failed video to the state."""
        self.failed_videos[video_id] = error
        self.last_updated = datetime.utcnow().isoformat()

    @classmethod
    def create(cls, playlist_id: str, file_search_store_name: str) -> "PlaylistState":
        """Create a new PlaylistState."""
        now = datetime.utcnow().isoformat()
        return cls(
            playlist_id=playlist_id,
            file_search_store_name=file_search_store_name,
            created_at=now,
            last_updated=now,
        )
