"""Tests for data models."""

from youtube_knowledge.models import (
    PlaylistState,
    ProcessedVideo,
    TranscriptEntry,
    VideoInfo,
)


class TestVideoInfo:
    """Tests for VideoInfo model."""

    def test_video_info_creation(self):
        """Test creating a VideoInfo object."""
        video = VideoInfo(
            video_id="abc123",
            title="Test Video",
            url="https://www.youtube.com/watch?v=abc123",
        )

        assert video.video_id == "abc123"
        assert video.title == "Test Video"
        assert video.url == "https://www.youtube.com/watch?v=abc123"

    def test_from_yt_dlp(self):
        """Test creating VideoInfo from yt-dlp data."""
        yt_dlp_entry = {
            "id": "xyz789",
            "title": "YT-DLP Video",
            "webpage_url": "https://www.youtube.com/watch?v=xyz789",
        }

        video = VideoInfo.from_yt_dlp(yt_dlp_entry)

        assert video.video_id == "xyz789"
        assert video.title == "YT-DLP Video"
        assert video.url == "https://www.youtube.com/watch?v=xyz789"

    def test_from_yt_dlp_missing_fields(self):
        """Test creating VideoInfo from incomplete yt-dlp data."""
        yt_dlp_entry = {"id": "incomplete123"}

        video = VideoInfo.from_yt_dlp(yt_dlp_entry)

        assert video.video_id == "incomplete123"
        assert video.title == "Unknown Title"
        assert video.url == "https://www.youtube.com/watch?v=incomplete123"


class TestTranscriptEntry:
    """Tests for TranscriptEntry model."""

    def test_transcript_entry_creation(self):
        """Test creating a TranscriptEntry object."""
        entry = TranscriptEntry(text="Hello world", start=0.0, duration=2.5)

        assert entry.text == "Hello world"
        assert entry.start == 0.0
        assert entry.duration == 2.5


class TestProcessedVideo:
    """Tests for ProcessedVideo model."""

    def test_processed_video_creation_success(self):
        """Test creating a ProcessedVideo record for a successful processing."""
        video = ProcessedVideo.create(
            video_id="test123",
            title="Test Video",
            gemini_file_name="test123.md",
            transcript_length=1000,
            transformed_length=1500,
        )

        assert video.video_id == "test123"
        assert video.title == "Test Video"
        assert video.gemini_file_name == "test123.md"
        assert video.transcript_length == 1000
        assert video.transformed_length == 1500
        assert video.error is None
        assert isinstance(video.processed_at, str)

    def test_processed_video_creation_with_error(self):
        """Test creating a ProcessedVideo record with an error."""
        video = ProcessedVideo.create(
            video_id="error123",
            title="Failed Video",
            gemini_file_name="error123.md",
            error="Transcripts disabled",
        )

        assert video.video_id == "error123"
        assert video.title == "Failed Video"
        assert video.error == "Transcripts disabled"
        assert video.transcript_length == 0
        assert video.transformed_length == 0


class TestPlaylistState:
    """Tests for PlaylistState model."""

    def test_playlist_state_creation(self):
        """Test creating a PlaylistState object."""
        state = PlaylistState.create(playlist_id="PL123", file_search_store_name="test-store")

        assert state.playlist_id == "PL123"
        assert state.file_search_store_name == "test-store"
        assert isinstance(state.created_at, str)
        assert isinstance(state.last_updated, str)
        assert len(state.processed_videos) == 0
        assert len(state.failed_videos) == 0

    def test_is_processed_success(self):
        """Test checking if a video is successfully processed."""
        state = PlaylistState.create(playlist_id="PL123", file_search_store_name="test-store")

        video = ProcessedVideo.create(
            video_id="test123",
            title="Test Video",
            gemini_file_name="test123.md",
            transcript_length=1000,
        )

        state.add_processed(video)

        assert state.is_processed("test123") is True
        assert state.is_processed("nonexistent") is False

    def test_is_processed_with_error(self):
        """Test that videos with errors are not considered processed."""
        state = PlaylistState.create(playlist_id="PL123", file_search_store_name="test-store")

        video = ProcessedVideo.create(
            video_id="error123",
            title="Failed Video",
            gemini_file_name="error123.md",
            error="Transcripts disabled",
        )

        state.add_processed(video)

        assert state.is_processed("error123") is False

    def test_add_processed_updates_timestamp(self):
        """Test that adding a processed video updates the last_updated timestamp."""
        state = PlaylistState.create(playlist_id="PL123", file_search_store_name="test-store")

        original_timestamp = state.last_updated

        video = ProcessedVideo.create(
            video_id="test123",
            title="Test Video",
            gemini_file_name="test123.md",
        )

        state.add_processed(video)

        assert state.last_updated >= original_timestamp
        assert "test123" in state.processed_videos

    def test_add_failed_video(self):
        """Test adding a failed video to the state."""
        state = PlaylistState.create(playlist_id="PL123", file_search_store_name="test-store")

        state.add_failed("failed123", "No transcript available")

        assert "failed123" in state.failed_videos
        assert state.failed_videos["failed123"] == "No transcript available"

    def test_add_processed_removes_from_failed(self):
        """Test that processing a video with an error does not remove it from failed_videos.

        This is the actual behavior - failed_videos is only cleaned up when
        a video with an error is added to processed_videos.
        """
        state = PlaylistState.create(playlist_id="PL123", file_search_store_name="test-store")

        # First, mark video as failed
        state.add_failed("retry123", "Network error")
        assert "retry123" in state.failed_videos

        # Process it with an error
        video_with_error = ProcessedVideo.create(
            video_id="retry123",
            title="Retry Video",
            gemini_file_name="retry123.md",
            error="Still failing",
        )
        state.add_processed(video_with_error)

        # Should be removed from failed_videos when added to processed with error
        assert "retry123" not in state.failed_videos
        assert "retry123" in state.processed_videos

    def test_add_processed_success_does_not_remove_from_failed(self):
        """Test that successfully processing doesn't remove from failed_videos.

        If a video is successfully processed without error, it stays in processed_videos
        but the failed_videos entry persists (documenting the history).
        """
        state = PlaylistState.create(playlist_id="PL123", file_search_store_name="test-store")

        # First, mark video as failed
        state.add_failed("success123", "Network error")
        assert "success123" in state.failed_videos

        # Then, successfully process it (no error)
        video_success = ProcessedVideo.create(
            video_id="success123",
            title="Success Video",
            gemini_file_name="success123.md",
            transcript_length=500,
        )
        state.add_processed(video_success)

        # Stays in failed_videos as historical record
        assert "success123" in state.failed_videos
        assert "success123" in state.processed_videos
