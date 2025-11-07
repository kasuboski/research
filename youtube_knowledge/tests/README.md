# Test Suite

This directory contains comprehensive tests for the YouTube Knowledge Base project.

## Overview

All tests use pytest with mocking to ensure no external API calls are made. The test suite includes:

- **Unit tests**: Test individual components in isolation
- **Mocked external APIs**: All YouTube API and Gemini API calls are mocked
- **Comprehensive coverage**: Tests cover success paths, error handling, and edge cases

## Structure

```
tests/
├── __init__.py              # Package marker
├── conftest.py              # Shared fixtures and test utilities
├── test_models.py           # Tests for data models
├── test_transcript.py       # Tests for TranscriptRetriever
├── test_playlist.py         # Tests for PlaylistFetcher
├── test_transform.py        # Tests for TranscriptTransformer
└── test_uploader.py         # Tests for GeminiUploader
```

## Running Tests

### Install Test Dependencies

```bash
pip install -e ".[test]"
```

### Run All Tests

```bash
pytest
```

### Run Tests with Coverage

```bash
pytest --cov=youtube_knowledge --cov-report=html
```

This generates an HTML coverage report in `htmlcov/index.html`.

### Run Specific Test Files

```bash
# Test only the transcript module
pytest tests/test_transcript.py

# Test only the uploader module
pytest tests/test_uploader.py
```

### Run Specific Test Classes or Functions

```bash
# Run a specific test class
pytest tests/test_transcript.py::TestTranscriptRetriever

# Run a specific test function
pytest tests/test_transcript.py::TestTranscriptRetriever::test_get_transcript_success
```

### Run with Verbose Output

```bash
pytest -v
```

## Test Fixtures

Common fixtures are defined in `conftest.py`:

- `sample_video_id`: Sample YouTube video ID
- `sample_video_info`: Sample VideoInfo object
- `sample_transcript_data`: Sample raw transcript data from YouTube API
- `sample_transcript_entries`: Sample TranscriptEntry objects
- `sample_playlist_id`: Sample YouTube playlist ID
- `sample_playlist_data`: Sample playlist data from yt-dlp
- `mock_gemini_api_key`: Mock Gemini API key
- `sample_transformed_content`: Sample transformed content from Gemini

## Key Testing Features

### 1. All External APIs are Mocked

No real API calls are made during testing. All external dependencies are mocked using `pytest-mock`:

- YouTube Transcript API (`youtube_transcript_api`)
- yt-dlp for playlist fetching
- Google Gemini API for transformation and upload

### 2. Bug Regression Tests

The test suite includes specific tests to catch bugs like:

- `test_api_not_instantiated`: Ensures `YouTubeTranscriptApi` is used as a static class
- `test_uses_static_method`: Verifies static method usage instead of instance methods

### 3. Error Handling Coverage

All error paths are tested:

- Transcripts disabled
- No transcript found
- Video unavailable
- Network errors
- API exceptions

### 4. Edge Cases

Tests cover edge cases like:

- Missing or malformed data
- Empty responses
- Null entries in playlists
- Failed operations

## Test Markers

Tests can be marked with custom markers:

- `@pytest.mark.unit`: Unit tests
- `@pytest.mark.integration`: Integration tests (currently all tests are unit tests)

## Writing New Tests

When adding new features:

1. Add shared fixtures to `conftest.py` if they'll be used across multiple test files
2. Create a new test file `test_<module>.py` for new modules
3. Use descriptive test names: `test_<function>_<scenario>`
4. Mock all external API calls using `mocker.patch()`
5. Include docstrings explaining what each test validates
6. Test both success and failure paths

## Continuous Integration

The test configuration in `pyproject.toml` includes:

- Coverage reporting (terminal and HTML)
- Strict marker mode (prevents typos in test markers)
- Verbose output by default
- Automatic test discovery

## Coverage Goals

Target coverage: 90%+ for all modules

Check current coverage:

```bash
pytest --cov=youtube_knowledge --cov-report=term-missing
```
