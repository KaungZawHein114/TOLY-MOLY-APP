from unittest.mock import MagicMock, patch

from django.test import TestCase, override_settings

from apps.tasks.models import Task
from apps.tasks.services import (
    AIServiceUnavailable,
    analyze_task,
    compute_budget_options,
    transcribe_audio,
)


class ComputeBudgetOptionsTests(TestCase):
    def test_returns_all_three_tiers(self):
        options = compute_budget_options("Plumber", Task.URGENCY_NORMAL)
        self.assertEqual(set(options.keys()), {"ECONOMY", "STANDARD", "PROFESSIONAL"})

    def test_tier_bands_match_worker_tier_numbers(self):
        options = compute_budget_options("Plumber", Task.URGENCY_NORMAL)
        self.assertEqual((options["ECONOMY"]["worker_tier_min"], options["ECONOMY"]["worker_tier_max"]), (1, 3))
        self.assertEqual((options["STANDARD"]["worker_tier_min"], options["STANDARD"]["worker_tier_max"]), (4, 5))
        self.assertEqual(
            (options["PROFESSIONAL"]["worker_tier_min"], options["PROFESSIONAL"]["worker_tier_max"]), (6, 7)
        )

    def test_professional_costs_more_than_economy(self):
        options = compute_budget_options("Plumber", Task.URGENCY_NORMAL)
        self.assertGreater(options["PROFESSIONAL"]["budget_mmk"], options["STANDARD"]["budget_mmk"])
        self.assertGreater(options["STANDARD"]["budget_mmk"], options["ECONOMY"]["budget_mmk"])

    def test_urgent_costs_more_than_normal(self):
        normal = compute_budget_options("Plumber", Task.URGENCY_NORMAL)
        urgent = compute_budget_options("Plumber", Task.URGENCY_URGENT)
        self.assertGreater(urgent["STANDARD"]["budget_mmk"], normal["STANDARD"]["budget_mmk"])

    def test_unknown_category_falls_back_to_default_base(self):
        options = compute_budget_options("SomethingNotInTheList", Task.URGENCY_NORMAL)
        self.assertIn("STANDARD", options)
        self.assertGreater(options["STANDARD"]["budget_mmk"], 0)


@override_settings(OPENAI_API_KEY="")
class AIUnavailableTests(TestCase):
    def test_transcribe_raises_when_key_missing(self):
        with self.assertRaises(AIServiceUnavailable):
            transcribe_audio(b"fake-bytes")

    def test_analyze_raises_when_key_missing(self):
        with self.assertRaises(AIServiceUnavailable):
            analyze_task("hello", [], {})


@override_settings(OPENAI_API_KEY="test-key")
class TranscribeAudioTests(TestCase):
    @patch("apps.tasks.services.OpenAI")
    def test_returns_transcript_text(self, mock_openai_cls):
        mock_client = MagicMock()
        mock_client.audio.transcriptions.create.return_value = MagicMock(text="ရေယိုနေတယ်")
        mock_openai_cls.return_value = mock_client

        result = transcribe_audio(b"fake-bytes", filename="rec.m4a", content_type="audio/m4a")

        self.assertEqual(result, "ရေယိုနေတယ်")
        mock_client.audio.transcriptions.create.assert_called_once()

    @patch("apps.tasks.services.OpenAI")
    def test_wraps_sdk_errors(self, mock_openai_cls):
        mock_client = MagicMock()
        mock_client.audio.transcriptions.create.side_effect = RuntimeError("network down")
        mock_openai_cls.return_value = mock_client

        with self.assertRaises(AIServiceUnavailable):
            transcribe_audio(b"fake-bytes")


@override_settings(OPENAI_API_KEY="test-key")
class AnalyzeTaskTests(TestCase):
    def _mock_response(self, mock_openai_cls, payload_json):
        mock_client = MagicMock()
        mock_message = MagicMock()
        mock_message.content = payload_json
        mock_choice = MagicMock()
        mock_choice.message = mock_message
        mock_client.chat.completions.create.return_value = MagicMock(choices=[mock_choice])
        mock_openai_cls.return_value = mock_client
        return mock_client

    @patch("apps.tasks.services.OpenAI")
    def test_merges_extracted_fields_with_known_fields(self, mock_openai_cls):
        self._mock_response(
            mock_openai_cls,
            '{"category": "Cleaner", "title": "House cleaning", "description": "Clean apartment", '
            '"township": "Kamayut", "date": "2026-07-01", "time": null, "urgency": null, '
            '"category_fields": {}, "reply": "What time should the worker arrive?", "ready": false}',
        )

        result = analyze_task("I need cleaning tomorrow", [], {"urgency": "NORMAL"})

        self.assertEqual(result["fields"]["category"], "Cleaner")
        self.assertEqual(result["fields"]["urgency"], "NORMAL")  # preserved from known_fields
        self.assertFalse(result["ready"])
        self.assertEqual(result["reply"], "What time should the worker arrive?")

    @patch("apps.tasks.services.OpenAI")
    def test_ready_true_only_when_every_required_field_present(self, mock_openai_cls):
        self._mock_response(
            mock_openai_cls,
            '{"category": "Cleaner", "title": "House cleaning", "description": "Clean apartment", '
            '"township": "Kamayut", "date": "2026-07-01", "time": "09:00", "urgency": "NORMAL", '
            '"category_fields": {"size": "2 bedrooms"}, "reply": "So: clean a 2-bedroom '
            'apartment in Kamayut tomorrow at 9am — sound right?", "ready": true}',
        )

        result = analyze_task("ok", [], {})

        self.assertTrue(result["ready"])
        self.assertIn("sound right", result["reply"])
        self.assertEqual(result["fields"]["category_fields"]["size"], "2 bedrooms")

    @patch("apps.tasks.services.OpenAI")
    def test_model_ready_true_overridden_when_a_required_field_is_still_missing(self, mock_openai_cls):
        # The model can be wrong — the backend never trusts ready:true blindly
        # if a flat required field it can actually verify is still empty.
        self._mock_response(
            mock_openai_cls,
            '{"category": "Cleaner", "title": "House cleaning", "description": null, '
            '"township": null, "date": null, "time": null, "urgency": null, '
            '"category_fields": {}, "reply": "Sounds good!", "ready": true}',
        )

        result = analyze_task("ok", [], {})

        self.assertFalse(result["ready"])

    @patch("apps.tasks.services.OpenAI")
    def test_category_fields_merge_without_discarding_prior_keys(self, mock_openai_cls):
        self._mock_response(
            mock_openai_cls,
            '{"category": "Tutor", "title": "Math tutoring", "description": "Grade 9 math", '
            '"township": "Bahan", "date": "flexible", "time": "flexible", "urgency": "NORMAL", '
            '"category_fields": {"frequency": "twice a week"}, "reply": "In-person or online?", '
            '"ready": false}',
        )

        result = analyze_task(
            "twice a week please",
            [],
            {"category": "Tutor", "category_fields": {"subject": "Math", "grade": "9"}},
        )

        self.assertEqual(
            result["fields"]["category_fields"],
            {"subject": "Math", "grade": "9", "frequency": "twice a week"},
        )

    @patch("apps.tasks.services.OpenAI")
    def test_wraps_sdk_errors(self, mock_openai_cls):
        mock_client = MagicMock()
        mock_client.chat.completions.create.side_effect = RuntimeError("rate limited")
        mock_openai_cls.return_value = mock_client

        with self.assertRaises(AIServiceUnavailable):
            analyze_task("hello", [], {})

    @patch("apps.tasks.services.OpenAI")
    def test_missing_reply_raises_unavailable(self, mock_openai_cls):
        self._mock_response(mock_openai_cls, '{"category": "Cleaner", "ready": false}')

        with self.assertRaises(AIServiceUnavailable):
            analyze_task("hello", [], {})
