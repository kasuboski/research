"""Playlist video fetching using yt-dlp."""

from typing import Optional

import yt_dlp

from .models import VideoInfo


class PlaylistFetcher:
    """Fetches video information from YouTube playlists."""

    def __init__(self):
        """Initialize the playlist fetcher."""
        self.ydl_opts = {
            "quiet": True,
            "no_warnings": True,
            "extract_flat": True,  # Don't download, just get metadata
        }

    def fetch_videos(self, playlist_id: str) -> list[VideoInfo]:
        """Fetch all videos from a playlist.

        Args:
            playlist_id: YouTube playlist ID

        Returns:
            List of VideoInfo objects

        Raises:
            Exception: If playlist cannot be fetched
        """
        playlist_url = self._get_playlist_url(playlist_id)

        try:
            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                info = ydl.extract_info(playlist_url, download=False)

                if not info:
                    raise ValueError(f"No information found for playlist {playlist_id}")

                videos = []
                entries = info.get("entries", [])

                for entry in entries:
                    if entry:  # Skip None entries (deleted/private videos)
                        try:
                            video = VideoInfo.from_yt_dlp(entry)
                            videos.append(video)
                        except Exception as e:
                            print(f"Warning: Failed to parse video entry: {e}")
                            continue

                return videos

        except Exception as e:
            raise Exception(f"Failed to fetch playlist {playlist_id}: {str(e)}")

    def get_playlist_title(self, playlist_id: str) -> Optional[str]:
        """Get the title of a playlist.

        Args:
            playlist_id: YouTube playlist ID

        Returns:
            Playlist title or None if unavailable
        """
        playlist_url = self._get_playlist_url(playlist_id)

        try:
            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                info = ydl.extract_info(playlist_url, download=False)
                return info.get("title") if info else None
        except Exception:
            return None

    def _get_playlist_url(self, playlist_id: str) -> str:
        """Convert playlist ID to URL.

        Args:
            playlist_id: Playlist ID (can be just ID or full URL)

        Returns:
            Full playlist URL
        """
        if playlist_id.startswith("http"):
            return playlist_id

        # Clean up playlist ID if it has extra parameters
        if "list=" in playlist_id:
            playlist_id = playlist_id.split("list=")[1].split("&")[0]

        return f"https://www.youtube.com/playlist?list={playlist_id}"
