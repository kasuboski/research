# YouTube Knowledge Base

Transform YouTube playlists into searchable knowledge bases using Google Gemini's File Search API.

## Overview

This tool automatically processes YouTube playlist videos by:
1. Extracting video transcripts
2. Using AI (Gemini) to transform transcripts into well-structured knowledge documents
3. Uploading to Gemini File Search for semantic search
4. Providing an interactive chat interface to query the knowledge base

## Features

- 🎥 **Playlist Processing** - Fetch all videos from a YouTube playlist
- 📝 **Transcript Extraction** - Automatic transcript retrieval with multi-language support
- 🤖 **AI Transformation** - Gemini transforms transcripts into structured, searchable knowledge documents
- 🔍 **Semantic Search** - Query your knowledge base using natural language
- 💬 **Interactive Chat** - Chat interface to ask questions about video content
- ♻️ **Idempotent Processing** - Safely rerun without reprocessing existing videos
- 📊 **State Management** - Track processed videos and failed attempts

## Installation

This project uses [uv](https://github.com/astral-sh/uv) for Python package management.

```bash
cd youtube_knowledge
uv sync
```

## Configuration

Set your Google Gemini API key as an environment variable:

```bash
export GOOGLE_API_KEY="your-api-key-here"
# or
export GEMINI_API_KEY="your-api-key-here"
```

Get your API key from: https://aistudio.google.com/app/apikey

## Usage

### Process a Playlist

Transform all videos in a playlist into a knowledge base:

```bash
# Using playlist ID
uv run yt_knowledge process --playlist-id PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf

# Using full playlist URL
uv run yt_knowledge process --playlist-id "https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"

# With custom store name
uv run yt_knowledge process --playlist-id PLxxx --store-name "my-custom-kb"

# Process with different language preferences
uv run yt_knowledge process --playlist-id PLxxx --languages en,es,fr

# Force reprocess all videos
uv run yt_knowledge process --playlist-id PLxxx --reprocess
```

### Chat with Knowledge Base

Ask questions about the processed videos:

```bash
# Interactive chat mode
uv run yt_knowledge chat --playlist-id PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf

# Single query mode
uv run yt_knowledge chat --playlist-id PLxxx --query "What are the main topics covered?"

# List available knowledge bases
uv run yt_knowledge chat
```

### List Processed Playlists

View all processed playlists and their status:

```bash
uv run yt_knowledge list
```

## How It Works

### 1. Playlist Fetching
Uses `yt-dlp` to extract video IDs and metadata from a YouTube playlist without authentication.

### 2. Transcript Retrieval
Uses `youtube-transcript-api` to fetch transcripts in preferred languages, with automatic fallback to auto-generated captions.

### 3. AI Transformation
Gemini 2.0 Flash transforms raw transcripts into structured knowledge documents with:
- Executive summaries
- Hierarchical section organization
- Key concepts and definitions
- Timestamped important moments
- Examples and case studies
- Actionable takeaways
- Markdown formatting for readability

### 4. File Upload & Indexing
Documents are uploaded to Gemini File Search with:
- Deterministic naming for idempotency
- Semantic chunking (500 tokens/chunk, 50 token overlap)
- Persistent storage in File Search Stores

### 5. Semantic Search & Chat
Queries leverage Gemini's File Search tool to:
- Perform semantic (not keyword) search
- Retrieve relevant context from multiple videos
- Generate comprehensive answers with source citations

## Project Structure

```
youtube_knowledge/
├── pyproject.toml              # uv project configuration
├── README.md                   # This file
├── .gitignore                  # Git ignore rules
├── youtube_knowledge/          # Main package
│   ├── __init__.py            # Package exports
│   ├── __main__.py            # CLI entry point
│   ├── cli.py                 # Click CLI commands
│   ├── models.py              # Data classes (@dataclass)
│   ├── playlist.py            # Playlist fetching (yt-dlp)
│   ├── transcript.py          # Transcript retrieval
│   ├── transform.py           # AI transformation (Gemini)
│   ├── uploader.py            # File upload to Gemini
│   ├── state.py               # State management
│   └── chat.py                # Chat interface
└── .state/                     # State files (git-ignored)
    └── playlists/
        └── {playlist_id}.json
```

## Architecture

### Data Flow

```
Playlist ID
    ↓
[yt-dlp] → List of (video_id, title)
    ↓
For each video:
    ↓
[Check State] → Skip if processed
    ↓
[youtube-transcript-api] → Raw transcript
    ↓
[Gemini 2.0 Flash] → Structured knowledge document
    ↓
[Gemini File Search] → Upload & index
    ↓
[Update State] → Save progress
```

### State Management

Each playlist has a state file (`.state/playlists/{playlist_id}.json`) tracking:
- Processed videos with metadata
- Failed videos with error messages
- File search store information
- Processing timestamps

This enables **idempotent processing** - rerun safely without duplicating work.

### Models

The project uses modern Python with type annotations and `@dataclass`:

- `VideoInfo` - YouTube video metadata
- `TranscriptEntry` - Single transcript segment with timing
- `ProcessedVideo` - Record of processed video
- `PlaylistState` - Complete playlist processing state

## Cost Considerations

### Gemini API Pricing

- **Indexing**: $0.15 per 1M tokens (one-time per video)
- **Queries**: Free (retrieved tokens charged as context)
- **Storage**: 1 GB free, then tiered pricing

### Typical Costs

- 10-minute video transcript: ~2,000 tokens
- Transformed document: ~4,000 tokens
- **Cost per video**: ~$0.001 (less than a penny!)
- **100-video playlist**: ~$0.10

### Rate Limits (Tier 1+)

- 1,000 requests/minute
- 1M tokens/minute

## Advanced Usage

### Custom Transformation Model

```python
from youtube_knowledge import TranscriptTransformer

transformer = TranscriptTransformer(
    api_key="your-key",
    model="gemini-2.0-flash-exp"  # or "gemini-1.5-pro"
)
```

### Programmatic Usage

```python
from youtube_knowledge import (
    PlaylistFetcher,
    TranscriptRetriever,
    TranscriptTransformer,
    GeminiUploader,
    StateManager,
)

# Fetch videos
fetcher = PlaylistFetcher()
videos = fetcher.fetch_videos("PLxxx")

# Get transcript
retriever = TranscriptRetriever(languages=["en"])
transcript = retriever.get_transcript(videos[0].video_id)

# Transform
transformer = TranscriptTransformer(api_key="xxx")
transformed = transformer.transform(
    videos[0],
    transcript,
    retriever.format_transcript(transcript)
)

# Upload
uploader = GeminiUploader(api_key="xxx")
store = uploader.get_or_create_file_search_store("my-kb")
uploader.upload_document(transformed, f"youtube-{videos[0].video_id}", store)
```

## Troubleshooting

### No Transcripts Available

Some videos don't have transcripts enabled. The tool will skip these and log warnings.

### IP Blocking

YouTube may block requests from cloud providers. If using in cloud environments, consider:
- Using a proxy
- Running locally
- Rate limiting requests

### API Key Issues

Ensure your API key is valid and has access to:
- Gemini API
- File API
- File Search API

Test your key: https://aistudio.google.com/

### State Corruption

If state becomes corrupted, delete the state file and reprocess:

```bash
rm .state/playlists/{playlist_id}.json
uv run yt_knowledge process --playlist-id {playlist_id}
```

## Development

### Running Tests

```bash
uv run pytest
```

### Code Style

This project uses:
- Type annotations throughout
- `@dataclass` for data models
- Functional programming style
- Modern Python 3.11+ features

### Adding New Features

The modular architecture makes it easy to extend:

1. **New transcript sources** - Implement in `transcript.py`
2. **Different transformations** - Modify `transform.py`
3. **Alternative storage** - Extend `uploader.py`
4. **New CLI commands** - Add to `cli.py`

## Limitations

- Requires transcripts to be available on YouTube
- Processing large playlists takes time (1-2 min per video)
- File Search limited to 100 MB per document
- Gemini context window: 1M tokens

## Future Enhancements

- [ ] Support for individual video URLs
- [ ] Parallel video processing
- [ ] Custom transformation prompts
- [ ] Export to other formats (PDF, HTML)
- [ ] Integration with other LLM providers
- [ ] Advanced filtering and search options

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

## Credits

Built with:
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Playlist fetching
- [youtube-transcript-api](https://github.com/jdepoix/youtube-transcript-api) - Transcript extraction
- [Google Gemini](https://ai.google.dev/gemini-api) - AI transformation and search
- [click](https://click.palletsprojects.com/) - CLI framework
- [rich](https://rich.readthedocs.io/) - Terminal UI
- [uv](https://github.com/astral-sh/uv) - Python package management

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review troubleshooting section above
