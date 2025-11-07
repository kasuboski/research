"""Shared fixtures for pytest tests."""

import pytest

from youtube_knowledge.models import TranscriptEntry, VideoInfo


@pytest.fixture
def sample_video_id():
    """Sample YouTube video ID."""
    return "dQw4w9WgXcQ"


@pytest.fixture
def sample_video_info():
    """Sample VideoInfo object."""
    return VideoInfo(
        video_id="dQw4w9WgXcQ",
        title="Sample Video Title",
        url="https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    )


@pytest.fixture
def sample_transcript_data():
    """Sample raw transcript data from YouTube API."""
    return [
        {"text": "Hello world", "start": 0.0, "duration": 2.5},
        {"text": "This is a test", "start": 2.5, "duration": 3.0},
        {"text": "Sample transcript", "start": 5.5, "duration": 2.0},
    ]


@pytest.fixture
def sample_transcript_entries():
    """Sample TranscriptEntry objects."""
    return [
        TranscriptEntry(text="Hello world", start=0.0, duration=2.5),
        TranscriptEntry(text="This is a test", start=2.5, duration=3.0),
        TranscriptEntry(text="Sample transcript", start=5.5, duration=2.0),
    ]


@pytest.fixture
def sample_playlist_id():
    """Sample YouTube playlist ID."""
    return "PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"


@pytest.fixture
def sample_playlist_data():
    """Sample playlist data from yt-dlp."""
    return {
        "title": "Sample Playlist",
        "entries": [
            {
                "id": "video1",
                "title": "First Video",
                "webpage_url": "https://www.youtube.com/watch?v=video1",
            },
            {
                "id": "video2",
                "title": "Second Video",
                "webpage_url": "https://www.youtube.com/watch?v=video2",
            },
            {
                "id": "video3",
                "title": "Third Video",
                "webpage_url": "https://www.youtube.com/watch?v=video3",
            },
        ],
    }


@pytest.fixture
def mock_gemini_api_key():
    """Mock Gemini API key."""
    return "mock-gemini-api-key-1234567890"


@pytest.fixture
def sample_transformed_content():
    """Sample transformed content from Gemini."""
    return """## Executive Summary

This video discusses sample topics with great detail.

## Key Concepts

- **Concept 1**: Important definition
- **Concept 2**: Another key idea

## Important Moments

- [00:00] Introduction to the topic
- [02:30] Main discussion begins

## Actionable Takeaways

1. First key takeaway
2. Second key takeaway
"""
