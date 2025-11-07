"""State management for playlist processing."""

import json
from pathlib import Path
from typing import Optional

from .models import PlaylistState, ProcessedVideo


class StateManager:
    """Manages persistent state for playlist processing."""

    def __init__(self, state_dir: Path = Path(".state/playlists")):
        """Initialize state manager.

        Args:
            state_dir: Directory to store state files
        """
        self.state_dir = state_dir
        self.state_dir.mkdir(parents=True, exist_ok=True)

    def _get_state_path(self, playlist_id: str) -> Path:
        """Get path to state file for a playlist."""
        return self.state_dir / f"{playlist_id}.json"

    def load(self, playlist_id: str) -> Optional[PlaylistState]:
        """Load state for a playlist.

        Args:
            playlist_id: YouTube playlist ID

        Returns:
            PlaylistState if exists, None otherwise
        """
        state_path = self._get_state_path(playlist_id)
        if not state_path.exists():
            return None

        try:
            with open(state_path, "r") as f:
                data = json.load(f)

            # Convert processed_videos dict to ProcessedVideo objects
            processed_videos = {
                video_id: ProcessedVideo(**video_data)
                for video_id, video_data in data.get("processed_videos", {}).items()
            }

            return PlaylistState(
                playlist_id=data["playlist_id"],
                file_search_store_name=data["file_search_store_name"],
                created_at=data["created_at"],
                last_updated=data["last_updated"],
                processed_videos=processed_videos,
                failed_videos=data.get("failed_videos", {}),
            )
        except (json.JSONDecodeError, KeyError) as e:
            print(f"Warning: Failed to load state for {playlist_id}: {e}")
            return None

    def save(self, state: PlaylistState) -> None:
        """Save state for a playlist.

        Args:
            state: PlaylistState to save
        """
        state_path = self._get_state_path(state.playlist_id)

        # Convert ProcessedVideo objects to dicts
        processed_videos = {
            video_id: {
                "video_id": video.video_id,
                "title": video.title,
                "processed_at": video.processed_at,
                "gemini_file_name": video.gemini_file_name,
                "transcript_length": video.transcript_length,
                "transformed_length": video.transformed_length,
                "error": video.error,
            }
            for video_id, video in state.processed_videos.items()
        }

        data = {
            "playlist_id": state.playlist_id,
            "file_search_store_name": state.file_search_store_name,
            "created_at": state.created_at,
            "last_updated": state.last_updated,
            "processed_videos": processed_videos,
            "failed_videos": state.failed_videos,
        }

        with open(state_path, "w") as f:
            json.dump(data, f, indent=2)

    def list_playlists(self) -> list[PlaylistState]:
        """List all tracked playlists.

        Returns:
            List of PlaylistState objects
        """
        playlists = []
        for state_file in self.state_dir.glob("*.json"):
            playlist_id = state_file.stem
            state = self.load(playlist_id)
            if state:
                playlists.append(state)
        return playlists

    def get_or_create(
        self, playlist_id: str, file_search_store_name: str
    ) -> PlaylistState:
        """Get existing state or create new one.

        Args:
            playlist_id: YouTube playlist ID
            file_search_store_name: Gemini file search store name

        Returns:
            PlaylistState
        """
        state = self.load(playlist_id)
        if state:
            return state

        return PlaylistState.create(
            playlist_id=playlist_id,
            file_search_store_name=file_search_store_name,
        )
