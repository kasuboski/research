"""Transcript retrieval from YouTube videos."""

from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._errors import (
    NoTranscriptFound,
    TranscriptsDisabled,
    VideoUnavailable,
)

from .models import TranscriptEntry


class TranscriptRetriever:
    """Retrieves transcripts from YouTube videos."""

    def __init__(self, languages: list[str] | None = None):
        """Initialize transcript retriever.

        Args:
            languages: Preferred languages for transcripts (e.g., ['en', 'de'])
                      Falls back to auto-generated if manual not available
        """
        self.languages = languages or ["en"]
        self.api = YouTubeTranscriptApi()

    def get_transcript(self, video_id: str) -> list[TranscriptEntry] | None:
        """Get transcript for a video.

        Args:
            video_id: YouTube video ID

        Returns:
            List of TranscriptEntry objects, or None if unavailable
        """
        try:
            # Fetch transcript in preferred languages
            fetched = self.api.fetch(video_id, languages=self.languages)

            # Convert to our model
            # FetchedTranscript is iterable and yields FetchedTranscriptSnippet dataclasses
            transcript = [
                TranscriptEntry(
                    text=entry.text,
                    start=entry.start,
                    duration=entry.duration,
                )
                for entry in fetched
            ]

            return transcript

        except TranscriptsDisabled:
            print(f"  ⚠️  Transcripts disabled for video {video_id}")
            return None
        except NoTranscriptFound:
            print(f"  ⚠️  No transcript found for video {video_id}")
            return None
        except VideoUnavailable:
            print(f"  ⚠️  Video {video_id} unavailable")
            return None
        except Exception as e:
            print(f"  ❌ Error fetching transcript for {video_id}: {e!s}")
            return None

    def format_transcript(self, transcript: list[TranscriptEntry]) -> str:
        """Format transcript entries into readable text.

        Args:
            transcript: List of TranscriptEntry objects

        Returns:
            Formatted transcript text with timestamps
        """
        lines = []
        for entry in transcript:
            timestamp = self._format_timestamp(entry.start)
            lines.append(f"[{timestamp}] {entry.text}")

        return "\n".join(lines)

    def format_transcript_plain(self, transcript: list[TranscriptEntry]) -> str:
        """Format transcript as plain text without timestamps.

        Args:
            transcript: List of TranscriptEntry objects

        Returns:
            Plain text transcript
        """
        return " ".join(entry.text for entry in transcript)

    def _format_timestamp(self, seconds: float) -> str:
        """Format seconds into MM:SS or HH:MM:SS.

        Args:
            seconds: Time in seconds

        Returns:
            Formatted timestamp string
        """
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)

        if hours > 0:
            return f"{hours:02d}:{minutes:02d}:{secs:02d}"
        return f"{minutes:02d}:{secs:02d}"
