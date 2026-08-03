from unittest.mock import MagicMock, patch

from django.test import TestCase, override_settings
from django.urls import reverse

from apps.matching.services import (
    FALLBACK_CATEGORY,
    SERVICE_CATEGORIES,
    MatchingServiceUnavailable,
    classify_category,
)


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
class MatchingUnavailableTests(TestCase):
    def test_raises_when_key_missing(self):
        with self.assertRaises(MatchingServiceUnavailable):
            classify_category("my sink is leaking")


@override_settings(OPENAI_API_KEY="test-key")
class ClassifyCategoryTests(TestCase):
    @patch("apps.matching.services.OpenAI")
    def test_returns_category_confidence_and_problem(self, mock_openai_cls):
        _mock_response(
            mock_openai_cls,
            '{"category": "Plumber", "confidence": 0.95, "problem": "sink is leaking"}',
        )

        result = classify_category("My sink is leaking")

        self.assertEqual(result["category"], "Plumber")
        self.assertEqual(result["confidence"], 0.95)
        self.assertEqual(result["problem"], "sink is leaking")

    @patch("apps.matching.services.OpenAI")
    def test_unknown_category_falls_back_instead_of_failing(self, mock_openai_cls):
        _mock_response(
            mock_openai_cls,
            '{"category": "Astronaut", "confidence": 0.2, "problem": "something odd"}',
        )

        result = classify_category("I need help with something")

        self.assertEqual(result["category"], FALLBACK_CATEGORY)
        self.assertIn(result["category"], SERVICE_CATEGORIES)

    @patch("apps.matching.services.OpenAI")
    def test_missing_category_falls_back(self, mock_openai_cls):
        _mock_response(mock_openai_cls, '{"confidence": 0.1}')

        result = classify_category("hmm")

        self.assertEqual(result["category"], FALLBACK_CATEGORY)
        self.assertEqual(result["problem"], "")

    @patch("apps.matching.services.OpenAI")
    def test_confidence_is_clamped_and_coerced(self, mock_openai_cls):
        _mock_response(
            mock_openai_cls,
            '{"category": "Cleaner", "confidence": 7, "problem": "clean my flat"}',
        )
        self.assertEqual(classify_category("clean my flat")["confidence"], 1.0)

        _mock_response(
            mock_openai_cls,
            '{"category": "Cleaner", "confidence": "very sure", "problem": "clean my flat"}',
        )
        self.assertEqual(classify_category("clean my flat")["confidence"], 0.0)

    @patch("apps.matching.services.OpenAI")
    def test_malformed_json_raises(self, mock_openai_cls):
        _mock_response(mock_openai_cls, "not json at all")

        with self.assertRaises(MatchingServiceUnavailable):
            classify_category("my sink is leaking")

    @patch("apps.matching.services.OpenAI")
    def test_openai_failure_raises(self, mock_openai_cls):
        mock_client = MagicMock()
        mock_client.chat.completions.create.side_effect = RuntimeError("network down")
        mock_openai_cls.return_value = mock_client

        with self.assertRaises(MatchingServiceUnavailable):
            classify_category("my sink is leaking")


@override_settings(OPENAI_API_KEY="test-key")
class ClassifyCategoryViewTests(TestCase):
    def _url(self):
        return reverse("matching-classify-category")

    @patch("apps.matching.services.OpenAI")
    def test_post_returns_200_with_classification(self, mock_openai_cls):
        _mock_response(
            mock_openai_cls,
            '{"category": "AC Technician", "confidence": 0.9, "problem": "aircon not cooling"}',
        )

        response = self.client.post(
            self._url(), {"message": "my air conditioner is not cooling"}, content_type="application/json"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["category"], "AC Technician")

    def test_blank_message_is_rejected(self):
        response = self.client.post(self._url(), {"message": "  "}, content_type="application/json")
        self.assertEqual(response.status_code, 400)

    @override_settings(OPENAI_API_KEY="")
    def test_unconfigured_server_returns_503(self):
        response = self.client.post(
            self._url(), {"message": "my sink is leaking"}, content_type="application/json"
        )

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["code"], "matching_unavailable")
