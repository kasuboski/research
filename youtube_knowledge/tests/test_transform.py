"""Tests for transcript transformation using Gemini."""

from google import genai

from youtube_knowledge.transform import TranscriptTransformer


class TestTranscriptTransformer:
    """Tests for TranscriptTransformer class."""

    def test_init(self, mock_gemini_api_key):
        """Test TranscriptTransformer initialization."""
        transformer = TranscriptTransformer(api_key=mock_gemini_api_key)

        assert transformer.model == "gemini-2.0-flash-exp"
        assert transformer.client is not None

    def test_init_custom_model(self, mock_gemini_api_key):
        """Test TranscriptTransformer initialization with custom model."""
        transformer = TranscriptTransformer(api_key=mock_gemini_api_key, model="gemini-1.5-pro")

        assert transformer.model == "gemini-1.5-pro"

    def test_transform_success(
        self,
        mocker,
        mock_gemini_api_key,
        sample_video_info,
        sample_transcript_entries,
        sample_transformed_content,
    ):
        """Test successful transcript transformation."""
        # Create a mock response object
        mock_response = mocker.MagicMock()
        mock_response.text = sample_transformed_content

        # Mock the Gemini client
        mock_client = mocker.MagicMock()
        mock_client.models.generate_content.return_value = mock_response

        mocker.patch.object(genai, "Client", return_value=mock_client)

        transformer = TranscriptTransformer(api_key=mock_gemini_api_key)
        formatted_transcript = "[00:00] Hello world\n[00:02] This is a test"

        result = transformer.transform(
            video=sample_video_info,
            transcript=sample_transcript_entries,
            formatted_transcript=formatted_transcript,
        )

        # Verify the result
        assert result is not None
        assert "title: Sample Video Title" in result
        assert "video_id: dQw4w9WgXcQ" in result
        assert "video_url:" in result
        assert sample_transformed_content in result

        # Verify the client was called correctly
        mock_client.models.generate_content.assert_called_once()
        call_kwargs = mock_client.models.generate_content.call_args[1]
        assert call_kwargs["model"] == "gemini-2.0-flash-exp"
        assert "Sample Video Title" in call_kwargs["contents"]
        assert formatted_transcript in call_kwargs["contents"]

    def test_transform_no_response(
        self,
        mocker,
        mock_gemini_api_key,
        sample_video_info,
        sample_transcript_entries,
    ):
        """Test handling of no response from Gemini."""
        # Mock the Gemini client to return None
        mock_client = mocker.MagicMock()
        mock_client.models.generate_content.return_value = None

        mocker.patch.object(genai, "Client", return_value=mock_client)

        transformer = TranscriptTransformer(api_key=mock_gemini_api_key)
        formatted_transcript = "[00:00] Hello world"

        result = transformer.transform(
            video=sample_video_info,
            transcript=sample_transcript_entries,
            formatted_transcript=formatted_transcript,
        )

        assert result is None

    def test_transform_empty_response_text(
        self,
        mocker,
        mock_gemini_api_key,
        sample_video_info,
        sample_transcript_entries,
    ):
        """Test handling of empty response text from Gemini."""
        # Create a mock response with empty text
        mock_response = mocker.MagicMock()
        mock_response.text = ""

        mock_client = mocker.MagicMock()
        mock_client.models.generate_content.return_value = mock_response

        mocker.patch.object(genai, "Client", return_value=mock_client)

        transformer = TranscriptTransformer(api_key=mock_gemini_api_key)
        formatted_transcript = "[00:00] Hello world"

        result = transformer.transform(
            video=sample_video_info,
            transcript=sample_transcript_entries,
            formatted_transcript=formatted_transcript,
        )

        assert result is None

    def test_transform_exception(
        self,
        mocker,
        mock_gemini_api_key,
        sample_video_info,
        sample_transcript_entries,
    ):
        """Test handling of exception during transformation."""
        # Mock the Gemini client to raise an exception
        mock_client = mocker.MagicMock()
        mock_client.models.generate_content.side_effect = Exception("API error")

        mocker.patch.object(genai, "Client", return_value=mock_client)

        transformer = TranscriptTransformer(api_key=mock_gemini_api_key)
        formatted_transcript = "[00:00] Hello world"

        result = transformer.transform(
            video=sample_video_info,
            transcript=sample_transcript_entries,
            formatted_transcript=formatted_transcript,
        )

        assert result is None

    def test_add_metadata_header(
        self, mocker, mock_gemini_api_key, sample_video_info, sample_transformed_content
    ):
        """Test metadata header is correctly added to transformed content."""
        # Mock the Gemini client
        mock_response = mocker.MagicMock()
        mock_response.text = sample_transformed_content

        mock_client = mocker.MagicMock()
        mock_client.models.generate_content.return_value = mock_response

        mocker.patch.object(genai, "Client", return_value=mock_client)

        transformer = TranscriptTransformer(api_key=mock_gemini_api_key)

        # Test the internal method
        result = transformer._add_metadata_header(sample_video_info, sample_transformed_content)

        # Verify metadata header format
        assert result.startswith("---\n")
        assert "title: Sample Video Title" in result
        assert "video_id: dQw4w9WgXcQ" in result
        assert "video_url: https://www.youtube.com/watch?v=dQw4w9WgXcQ" in result
        assert "source: YouTube" in result
        assert "type: video_transcript" in result
        assert "---\n" in result

        # Verify content is included after header
        assert sample_transformed_content in result

    def test_transform_prompt_includes_all_info(
        self,
        mocker,
        mock_gemini_api_key,
        sample_video_info,
        sample_transcript_entries,
    ):
        """Test that transformation prompt includes all necessary information."""
        mock_response = mocker.MagicMock()
        mock_response.text = "Transformed content"

        mock_client = mocker.MagicMock()
        mock_client.models.generate_content.return_value = mock_response

        mocker.patch.object(genai, "Client", return_value=mock_client)

        transformer = TranscriptTransformer(api_key=mock_gemini_api_key)
        formatted_transcript = "[00:00] Hello world\n[00:02] This is a test"

        transformer.transform(
            video=sample_video_info,
            transcript=sample_transcript_entries,
            formatted_transcript=formatted_transcript,
        )

        # Get the prompt that was sent to Gemini
        call_kwargs = mock_client.models.generate_content.call_args[1]
        prompt = call_kwargs["contents"]

        # Verify all necessary information is in the prompt
        assert sample_video_info.title in prompt
        assert sample_video_info.video_id in prompt
        assert sample_video_info.url in prompt
        assert formatted_transcript in prompt

        # Verify transformation guidelines are included
        assert "Executive Summary" in prompt
        assert "Structured Content" in prompt
        assert "Key Concepts" in prompt
        assert "Actionable Takeaways" in prompt

    def test_client_initialization_with_api_key(self, mocker, mock_gemini_api_key):
        """Test that the Gemini client is initialized with the provided API key."""
        mock_client_class = mocker.patch.object(genai, "Client")

        TranscriptTransformer(api_key=mock_gemini_api_key)

        mock_client_class.assert_called_once_with(api_key=mock_gemini_api_key)
