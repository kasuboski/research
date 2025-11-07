"""YouTube to Gemini Knowledge Base - Transform YouTube playlists into searchable knowledge bases."""

__version__ = "0.1.0"

from .chat import KnowledgeBaseChat
from .models import (
    PlaylistState,
    ProcessedVideo,
    TranscriptEntry,
    VideoInfo,
)
from .playlist import PlaylistFetcher
from .state import StateManager
from .transcript import TranscriptRetriever
from .transform import TranscriptTransformer
from .uploader import GeminiUploader

__all__ = [
    "KnowledgeBaseChat",
    "PlaylistState",
    "ProcessedVideo",
    "TranscriptEntry",
    "VideoInfo",
    "PlaylistFetcher",
    "StateManager",
    "TranscriptRetriever",
    "TranscriptTransformer",
    "GeminiUploader",
]
