"""Tests for transcript retrieval."""

from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._errors import (
    NoTranscriptFound,
    TranscriptsDisabled,
    VideoUnavailable,
)

from youtube_knowledge.models import TranscriptEntry
from youtube_knowledge.transcript import TranscriptRetriever


class TestTranscriptRetriever:
    """Tests for TranscriptRetriever class."""

    def test_init_default_languages(self):
        """Test TranscriptRetriever initialization with default languages."""
        retriever = TranscriptRetriever()

        assert retriever.languages == ["en"]

    def test_init_custom_languages(self):
        """Test TranscriptRetriever initialization with custom languages."""
        retriever = TranscriptRetriever(languages=["de", "fr"])

        assert retriever.languages == ["de", "fr"]

    def test_get_transcript_success(self, mocker, sample_video_id, sample_transcript_data):
        """Test successful transcript retrieval."""
        # Create mock transcript snippet objects with proper attributes
        mock_snippets = []
        for data in sample_transcript_data:
            snippet = mocker.MagicMock()
            snippet.text = data["text"]
            snippet.start = data["start"]
            snippet.duration = data["duration"]
            mock_snippets.append(snippet)

        # Mock the instance method on YouTubeTranscriptApi
        mock_api_instance = mocker.MagicMock()
        mock_api_instance.fetch.return_value = mock_snippets

        mocker.patch.object(YouTubeTranscriptApi, "__init__", return_value=None)
        mocker.patch.object(YouTubeTranscriptApi, "fetch", mock_api_instance.fetch)

        retriever = TranscriptRetriever()
        retriever.api = mock_api_instance
        result = retriever.get_transcript(sample_video_id)

        # Verify the mock was called correctly
        mock_api_instance.fetch.assert_called_once_with(sample_video_id, languages=["en"])

        # Verify the result
        assert result is not None
        assert len(result) == 3
        assert all(isinstance(entry, TranscriptEntry) for entry in result)
        assert result[0].text == "Hello world"
        assert result[0].start == 0.0
        assert result[0].duration == 2.5

    def test_get_transcript_with_custom_languages(
        self, mocker, sample_video_id, sample_transcript_data
    ):
        """Test transcript retrieval with custom languages."""
        # Create mock transcript snippet objects with proper attributes
        mock_snippets = []
        for data in sample_transcript_data:
            snippet = mocker.MagicMock()
            snippet.text = data["text"]
            snippet.start = data["start"]
            snippet.duration = data["duration"]
            mock_snippets.append(snippet)

        mock_api_instance = mocker.MagicMock()
        mock_api_instance.fetch.return_value = mock_snippets

        retriever = TranscriptRetriever(languages=["de", "en"])
        retriever.api = mock_api_instance
        result = retriever.get_transcript(sample_video_id)

        mock_api_instance.fetch.assert_called_once_with(sample_video_id, languages=["de", "en"])
        assert result is not None

    def test_get_transcript_transcripts_disabled(self, mocker, sample_video_id):
        """Test handling of transcripts disabled error."""
        mock_api_instance = mocker.MagicMock()
        mock_api_instance.fetch.side_effect = TranscriptsDisabled(sample_video_id)

        retriever = TranscriptRetriever()
        retriever.api = mock_api_instance
        result = retriever.get_transcript(sample_video_id)

        assert result is None

    def test_get_transcript_no_transcript_found(self, mocker, sample_video_id):
        """Test handling of no transcript found error."""
        mock_api_instance = mocker.MagicMock()
        mock_api_instance.fetch.side_effect = NoTranscriptFound(
            sample_video_id, ["en"], {"en": "Not available"}
        )

        retriever = TranscriptRetriever()
        retriever.api = mock_api_instance
        result = retriever.get_transcript(sample_video_id)

        assert result is None

    def test_get_transcript_video_unavailable(self, mocker, sample_video_id):
        """Test handling of video unavailable error."""
        mock_api_instance = mocker.MagicMock()
        mock_api_instance.fetch.side_effect = VideoUnavailable(sample_video_id)

        retriever = TranscriptRetriever()
        retriever.api = mock_api_instance
        result = retriever.get_transcript(sample_video_id)

        assert result is None

    def test_get_transcript_generic_exception(self, mocker, sample_video_id):
        """Test handling of generic exception during transcript retrieval."""
        mock_api_instance = mocker.MagicMock()
        mock_api_instance.fetch.side_effect = Exception("Unexpected error")

        retriever = TranscriptRetriever()
        retriever.api = mock_api_instance
        result = retriever.get_transcript(sample_video_id)

        assert result is None

    def test_format_transcript(self, sample_transcript_entries):
        """Test formatting transcript with timestamps."""
        retriever = TranscriptRetriever()
        formatted = retriever.format_transcript(sample_transcript_entries)

        assert "[00:00] Hello world" in formatted
        assert "[00:02] This is a test" in formatted
        assert "[00:05] Sample transcript" in formatted

    def test_format_transcript_plain(self, sample_transcript_entries):
        """Test formatting transcript as plain text without timestamps."""
        retriever = TranscriptRetriever()
        plain = retriever.format_transcript_plain(sample_transcript_entries)

        assert plain == "Hello world This is a test Sample transcript"

    def test_format_timestamp_seconds_only(self):
        """Test timestamp formatting for times under 1 minute."""
        retriever = TranscriptRetriever()

        assert retriever._format_timestamp(0) == "00:00"
        assert retriever._format_timestamp(30) == "00:30"
        assert retriever._format_timestamp(59) == "00:59"

    def test_format_timestamp_minutes_and_seconds(self):
        """Test timestamp formatting for times under 1 hour."""
        retriever = TranscriptRetriever()

        assert retriever._format_timestamp(60) == "01:00"
        assert retriever._format_timestamp(90) == "01:30"
        assert retriever._format_timestamp(3599) == "59:59"

    def test_format_timestamp_hours(self):
        """Test timestamp formatting for times over 1 hour."""
        retriever = TranscriptRetriever()

        assert retriever._format_timestamp(3600) == "01:00:00"
        assert retriever._format_timestamp(3661) == "01:01:01"
        assert retriever._format_timestamp(7384) == "02:03:04"

    def test_api_is_instantiated(self):
        """Test that YouTubeTranscriptApi is properly instantiated.

        This test ensures the API is instantiated as required by the library.
        """
        retriever = TranscriptRetriever()

        # The retriever should have an 'api' attribute
        assert hasattr(retriever, "api")

        # It should also have the languages attribute
        assert hasattr(retriever, "languages")

    def test_uses_instance_method(self, mocker, sample_video_id, sample_transcript_data):
        """Test that the retriever uses YouTubeTranscriptApi instance method.

        This test verifies that get_transcript calls the fetch method on an instance
        of the API, which is the correct usage pattern for youtube-transcript-api.
        """
        # Mock the instance method
        mock_api_instance = mocker.MagicMock()
        mock_api_instance.fetch.return_value = sample_transcript_data

        retriever = TranscriptRetriever()
        retriever.api = mock_api_instance
        retriever.get_transcript(sample_video_id)

        # Verify that the instance method was called
        mock_api_instance.fetch.assert_called_once()

        # Verify it was called with correct parameters
        mock_api_instance.fetch.assert_called_with(sample_video_id, languages=["en"])
