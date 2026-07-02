from unittest.mock import patch

from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.tasks.models import Task
from apps.users.models import User


class TaskApiTestBase(APITestCase):
    def setUp(self):
        self.client_user = User.objects.create_user(
            phone_number="09111111111", password="x", role="CLIENT", is_active=True
        )
        self.tasker_user = User.objects.create_user(
            phone_number="09222222222", password="x", role="TASKER", is_active=True
        )
        self.client_access = str(RefreshToken.for_user(self.client_user).access_token)
        self.tasker_access = str(RefreshToken.for_user(self.tasker_user).access_token)

    def _as_client(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.client_access}")

    def _as_tasker(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.tasker_access}")


class AnalyzeTaskEndpointTests(TaskApiTestBase):
    def setUp(self):
        super().setUp()
        self.url = reverse("task-ai-analyze")

    def test_requires_authentication(self):
        response = self.client.post(self.url, {"message": "hi"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_tasker_cannot_analyze(self):
        self._as_tasker()
        response = self.client.post(self.url, {"message": "hi"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    @override_settings(OPENAI_API_KEY="")
    def test_returns_503_when_ai_unavailable(self):
        self._as_client()
        response = self.client.post(self.url, {"message": "I need cleaning"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertEqual(response.data.get("code"), "ai_unavailable")

    @patch("apps.tasks.views.analyze_task")
    def test_returns_analysis_result(self, mock_analyze):
        mock_analyze.return_value = {
            "fields": {"category": "Cleaner"},
            "question": "What date?",
            "ready": False,
        }
        self._as_client()
        response = self.client.post(
            self.url,
            {"message": "I need cleaning", "history": [], "known_fields": {}},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["fields"]["category"], "Cleaner")
        self.assertFalse(response.data["ready"])


class TranscribeAudioEndpointTests(TaskApiTestBase):
    def setUp(self):
        super().setUp()
        self.url = reverse("task-ai-transcribe")

    def test_requires_audio_file(self):
        self._as_client()
        response = self.client.post(self.url, {}, format="multipart")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("code"), "audio_required")

    @patch("apps.tasks.views.transcribe_audio")
    def test_returns_transcribed_text(self, mock_transcribe):
        from django.core.files.uploadedfile import SimpleUploadedFile

        mock_transcribe.return_value = "ရေယိုနေတယ်"
        self._as_client()
        audio = SimpleUploadedFile("rec.m4a", b"fake-bytes", content_type="audio/m4a")
        response = self.client.post(self.url, {"audio": audio}, format="multipart")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["text"], "ရေယိုနေတယ်")


class BudgetOptionsEndpointTests(TaskApiTestBase):
    def setUp(self):
        super().setUp()
        self.url = reverse("task-ai-budget-options")

    def test_returns_three_tiers_no_ai_needed(self):
        self._as_client()
        response = self.client.post(self.url, {"category": "Plumber", "urgency": "NORMAL"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(set(response.data.keys()), {"ECONOMY", "STANDARD", "PROFESSIONAL"})


class TaskListCreateEndpointTests(TaskApiTestBase):
    def setUp(self):
        super().setUp()
        self.url = reverse("task-list-create")
        self.valid_payload = {
            "category": "Cleaner",
            "title": "House cleaning",
            "description": "Deep clean the living room",
            "date": "2026-07-01",
            "time": "09:00",
            "latitude": 16.8,
            "longitude": 96.15,
            "address": "Hlaing",
            "urgency": "NORMAL",
            "budget_tier": "STANDARD",
            "worker_tier_min": 4,
            "worker_tier_max": 5,
            "budget_mmk": 10000,
        }

    def test_tasker_cannot_publish(self):
        self._as_tasker()
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_client_publishes_task_as_pending(self):
        self._as_client()
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["status"], "PENDING")

        task = Task.objects.get(pk=response.data["id"])
        self.assertEqual(task.client, self.client_user)
        self.assertEqual(task.category, "Cleaner")

    def test_incomplete_task_rejected(self):
        self._as_client()
        payload = {**self.valid_payload}
        del payload["budget_tier"]
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("code"), "incomplete_task")

    def test_list_defaults_to_pending_task_board(self):
        Task.objects.create(client=self.client_user, category="Cleaner", title="A", status=Task.STATUS_PENDING)
        Task.objects.create(client=self.client_user, category="Cleaner", title="B", status=Task.STATUS_COMPLETED)
        self._as_tasker()  # any authenticated user can browse the board
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        titles = [t["title"] for t in response.data]
        self.assertIn("A", titles)
        self.assertNotIn("B", titles)

    def test_mine_filters_to_own_tasks_regardless_of_status(self):
        mine = Task.objects.create(
            client=self.client_user, category="Cleaner", title="Mine", status=Task.STATUS_COMPLETED
        )
        other_client = User.objects.create_user(phone_number="09133333333", password="x", role="CLIENT")
        Task.objects.create(client=other_client, category="Cleaner", title="NotMine", status=Task.STATUS_PENDING)

        self._as_client()
        response = self.client.get(self.url, {"mine": "true"})
        titles = [t["title"] for t in response.data]
        self.assertEqual(titles, ["Mine"])
        self.assertEqual(response.data[0]["id"], mine.id)


class TaskDetailEndpointTests(TaskApiTestBase):
    def test_returns_task_by_id(self):
        task = Task.objects.create(client=self.client_user, category="Cleaner", title="A")
        self._as_tasker()
        response = self.client.get(reverse("task-detail", args=[task.id]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "A")

    def test_404_for_unknown_task(self):
        self._as_client()
        response = self.client.get(reverse("task-detail", args=[999999]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
