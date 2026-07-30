from unittest.mock import MagicMock, patch

from django.test import TestCase, override_settings

from apps.assistant.services import AssistantServiceUnavailable, chat


def _mock_response(mock_openai_cls, payload_json):
    mock_client = MagicMock()
    mock_message = MagicMock()
    mock_message.content = payload_json
    mock_choice = MagicMock()
    mock_choice.message = mock_message
    mock_client.chat.completions.create.return_value = MagicMock(choices=[mock_choice])
    mock_openai_cls.return_value = mock_client
    return mock_client


@override_settings(OPENAI_API_KEY="")
class AssistantUnavailableTests(TestCase):
    def test_raises_when_key_missing(self):
        with self.assertRaises(AssistantServiceUnavailable):
            chat("hello", [])


@override_settings(OPENAI_API_KEY="test-key")
class ChatTests(TestCase):
    @patch("apps.assistant.services.OpenAI")
    def test_returns_message_and_action_id(self, mock_openai_cls):
        _mock_response(
            mock_openai_cls,
            '{"message": "Tap Post a Task, then AI Assistant.", "action_id": "post_task"}',
        )

        result = chat("I want to hire someone", [])

        self.assertEqual(result["message"], "Tap Post a Task, then AI Assistant.")
        self.assertEqual(result["action_id"], "post_task")

    @patch("apps.assistant.services.OpenAI")
    def test_unknown_action_id_is_dropped_not_rejected(self, mock_openai_cls):
        _mock_response(
            mock_openai_cls,
            '{"message": "Here is some info.", "action_id": "download_the_app"}',
        )

        result = chat("hello", [])

        self.assertEqual(result["message"], "Here is some info.")
        self.assertIsNone(result["action_id"])

    @patch("apps.assistant.services.OpenAI")
    def test_null_action_id_stays_null(self, mock_openai_cls):
        _mock_response(mock_openai_cls, '{"message": "Sure, happy to help.", "action_id": null}')

        result = chat("hello", [])

        self.assertIsNone(result["action_id"])

    @patch("apps.assistant.services.OpenAI")
    def test_malformed_json_raises_unavailable(self, mock_openai_cls):
        _mock_response(mock_openai_cls, "not json at all")

        with self.assertRaises(AssistantServiceUnavailable):
            chat("hello", [])

    @patch("apps.assistant.services.OpenAI")
    def test_missing_message_field_raises_unavailable(self, mock_openai_cls):
        _mock_response(mock_openai_cls, '{"action_id": "post_task"}')

        with self.assertRaises(AssistantServiceUnavailable):
            chat("hello", [])

    @patch("apps.assistant.services.OpenAI")
    def test_blank_message_field_raises_unavailable(self, mock_openai_cls):
        _mock_response(mock_openai_cls, '{"message": "   ", "action_id": null}')

        with self.assertRaises(AssistantServiceUnavailable):
            chat("hello", [])

    @patch("apps.assistant.services.OpenAI")
    def test_wraps_sdk_errors(self, mock_openai_cls):
        mock_client = MagicMock()
        mock_client.chat.completions.create.side_effect = RuntimeError("rate limited")
        mock_openai_cls.return_value = mock_client

        with self.assertRaises(AssistantServiceUnavailable):
            chat("hello", [])
