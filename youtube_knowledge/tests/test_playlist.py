"""Tests for playlist video fetching."""

import pytest
import yt_dlp

from youtube_knowledge.models import VideoInfo
from youtube_knowledge.playlist import PlaylistFetcher


class TestPlaylistFetcher:
    """Tests for PlaylistFetcher class."""

    def test_init(self):
        """Test PlaylistFetcher initialization."""
        fetcher = PlaylistFetcher()

        assert fetcher.ydl_opts == {
            "quiet": True,
            "no_warnings": True,
            "extract_flat": True,
        }

    def test_get_playlist_url_from_id(self):
        """Test converting playlist ID to URL."""
        fetcher = PlaylistFetcher()

        url = fetcher._get_playlist_url("PLtest123")

        assert url == "https://www.youtube.com/playlist?list=PLtest123"

    def test_get_playlist_url_from_full_url(self):
        """Test handling of full playlist URL."""
        fetcher = PlaylistFetcher()
        full_url = "https://www.youtube.com/playlist?list=PLtest123"

        url = fetcher._get_playlist_url(full_url)

        assert url == full_url

    def test_get_playlist_url_from_url_with_params(self):
        """Test extracting playlist ID from URL with extra parameters."""
        fetcher = PlaylistFetcher()

        url = fetcher._get_playlist_url("list=PLtest123&index=1&t=5s")

        assert url == "https://www.youtube.com/playlist?list=PLtest123"

    def test_fetch_videos_success(self, mocker, sample_playlist_id, sample_playlist_data):
        """Test successful playlist video fetching."""
        # Mock yt_dlp.YoutubeDL context manager
        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.return_value = sample_playlist_data
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()
        videos = fetcher.fetch_videos(sample_playlist_id)

        assert len(videos) == 3
        assert all(isinstance(video, VideoInfo) for video in videos)
        assert videos[0].video_id == "video1"
        assert videos[0].title == "First Video"
        assert videos[1].video_id == "video2"
        assert videos[2].video_id == "video3"

    def test_fetch_videos_with_none_entries(self, mocker, sample_playlist_id, sample_playlist_data):
        """Test fetching playlist with some deleted/private videos (None entries)."""
        # Add None entries to simulate deleted/private videos
        playlist_data = sample_playlist_data.copy()
        playlist_data["entries"] = [
            playlist_data["entries"][0],
            None,  # Deleted video
            playlist_data["entries"][1],
            None,  # Private video
            playlist_data["entries"][2],
        ]

        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.return_value = playlist_data
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()
        videos = fetcher.fetch_videos(sample_playlist_id)

        # Should skip None entries
        assert len(videos) == 3

    def test_fetch_videos_no_info(self, mocker, sample_playlist_id):
        """Test handling of no playlist information returned."""
        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.return_value = None
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()

        with pytest.raises(Exception) as exc_info:
            fetcher.fetch_videos(sample_playlist_id)

        assert "No information found" in str(exc_info.value)

    def test_fetch_videos_yt_dlp_exception(self, mocker, sample_playlist_id):
        """Test handling of yt-dlp exceptions."""
        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.side_effect = Exception("yt-dlp error")
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()

        with pytest.raises(Exception) as exc_info:
            fetcher.fetch_videos(sample_playlist_id)

        assert "Failed to fetch playlist" in str(exc_info.value)
        assert "yt-dlp error" in str(exc_info.value)

    def test_fetch_videos_handles_malformed_entry(
        self, mocker, sample_playlist_id, sample_playlist_data
    ):
        """Test handling of malformed video entries."""
        # Create playlist data with one malformed entry
        playlist_data = sample_playlist_data.copy()
        playlist_data["entries"] = [
            sample_playlist_data["entries"][0],
            {"id": "malformed"},  # Missing title and url
            sample_playlist_data["entries"][1],
        ]

        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.return_value = playlist_data
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()
        videos = fetcher.fetch_videos(sample_playlist_id)

        # Should still process valid entries
        assert len(videos) == 3  # Including the malformed one with defaults

    def test_get_playlist_title_success(self, mocker, sample_playlist_id, sample_playlist_data):
        """Test successfully retrieving playlist title."""
        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.return_value = sample_playlist_data
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()
        title = fetcher.get_playlist_title(sample_playlist_id)

        assert title == "Sample Playlist"

    def test_get_playlist_title_no_info(self, mocker, sample_playlist_id):
        """Test handling of missing playlist title."""
        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.return_value = None
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()
        title = fetcher.get_playlist_title(sample_playlist_id)

        assert title is None

    def test_get_playlist_title_exception(self, mocker, sample_playlist_id):
        """Test handling of exceptions when retrieving playlist title."""
        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.side_effect = Exception("Network error")
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()
        title = fetcher.get_playlist_title(sample_playlist_id)

        assert title is None

    def test_fetch_videos_calls_ydl_correctly(
        self, mocker, sample_playlist_id, sample_playlist_data
    ):
        """Test that YoutubeDL is called with correct options."""
        mock_ydl = mocker.MagicMock()
        mock_ydl.extract_info.return_value = sample_playlist_data
        mock_ydl.__enter__ = mocker.MagicMock(return_value=mock_ydl)
        mock_ydl.__exit__ = mocker.MagicMock(return_value=False)

        mock_ydl_class = mocker.patch.object(yt_dlp, "YoutubeDL", return_value=mock_ydl)

        fetcher = PlaylistFetcher()
        fetcher.fetch_videos(sample_playlist_id)

        # Verify YoutubeDL was called with correct options
        mock_ydl_class.assert_called_once_with(
            {"quiet": True, "no_warnings": True, "extract_flat": True}
        )

        # Verify extract_info was called with correct parameters
        mock_ydl.extract_info.assert_called_once()
        call_args = mock_ydl.extract_info.call_args
        assert "playlist?list=" in call_args[0][0]
        assert call_args[1]["download"] is False
