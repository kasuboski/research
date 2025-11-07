"""Transcript transformation using Gemini for knowledge optimization."""

from typing import Optional

from google import genai

from .models import VideoInfo, TranscriptEntry


TRANSFORMATION_PROMPT = """You are a knowledge curator tasked with transforming a YouTube video transcript into a well-structured document optimized for knowledge retention and semantic search.

Transform the following transcript into a comprehensive knowledge document following these guidelines:

## Transformation Guidelines:

1. **Executive Summary** (2-3 paragraphs)
   - Provide a high-level overview of the video's main topic and key takeaways
   - Highlight the most important insights or conclusions

2. **Structured Content**
   - Organize the content into logical sections with clear headers
   - Use hierarchical structure (H2, H3, H4) to show relationships
   - Group related concepts together

3. **Key Concepts & Definitions**
   - Extract and define important terms, concepts, or frameworks mentioned
   - Explain technical terms for easier understanding

4. **Important Moments** (with timestamps)
   - Preserve timestamps for particularly valuable segments
   - Highlight key quotes or explanations
   - Mark actionable insights or recommendations

5. **Examples & Case Studies**
   - Extract and clearly present any examples, analogies, or case studies
   - Show how concepts are applied in practice

6. **Cross-References & Connections**
   - Note relationships between different topics discussed
   - Reference prerequisite knowledge or related concepts

7. **Actionable Takeaways**
   - Summarize practical steps, recommendations, or best practices
   - List key learnings in a concise format

## Formatting:
- Use **Markdown** formatting for structure and emphasis
- Use bullet points and numbered lists where appropriate
- Use **bold** for key terms and *italics* for emphasis
- Use code blocks for any technical content or commands
- Preserve timestamps as `[MM:SS]` or `[HH:MM:SS]` format

## Output Quality:
- Make the document **searchable** - use clear, descriptive language
- Make it **scannable** - use formatting to guide the eye
- Make it **comprehensive** - don't lose important information
- Make it **accurate** - maintain the speaker's intended meaning

## Video Information:
- **Title**: {title}
- **Video ID**: {video_id}
- **URL**: {url}

## Transcript:
{transcript}

---

Transform this transcript into a well-structured knowledge document following the guidelines above.
"""


class TranscriptTransformer:
    """Transforms transcripts using Gemini for knowledge optimization."""

    def __init__(self, api_key: str, model: str = "gemini-2.0-flash-exp"):
        """Initialize the transcript transformer.

        Args:
            api_key: Google Gemini API key
            model: Gemini model to use (default: gemini-2.0-flash-exp)
        """
        self.client = genai.Client(api_key=api_key)
        self.model = model

    def transform(
        self,
        video: VideoInfo,
        transcript: list[TranscriptEntry],
        formatted_transcript: str,
    ) -> Optional[str]:
        """Transform a transcript into optimized knowledge document.

        Args:
            video: VideoInfo object with video metadata
            transcript: List of TranscriptEntry objects
            formatted_transcript: Pre-formatted transcript text with timestamps

        Returns:
            Transformed markdown document, or None on error
        """
        try:
            # Build the prompt with video information and transcript
            prompt = TRANSFORMATION_PROMPT.format(
                title=video.title,
                video_id=video.video_id,
                url=video.url,
                transcript=formatted_transcript,
            )

            # Generate transformed content using Gemini
            response = self.client.models.generate_content(
                model=self.model,
                contents=prompt,
            )

            if not response or not response.text:
                print(f"  ❌ No response from Gemini for video {video.video_id}")
                return None

            # Add metadata header to the document
            transformed = self._add_metadata_header(video, response.text)

            return transformed

        except Exception as e:
            print(f"  ❌ Error transforming transcript for {video.video_id}: {str(e)}")
            return None

    def _add_metadata_header(self, video: VideoInfo, content: str) -> str:
        """Add metadata header to transformed content.

        Args:
            video: VideoInfo object
            content: Transformed content

        Returns:
            Content with metadata header
        """
        header = f"""---
title: {video.title}
video_id: {video.video_id}
video_url: {video.url}
source: YouTube
type: video_transcript
---

"""
        return header + content
