import io
import shutil
import tempfile

from django.test import override_settings
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User
from apps.verification.models import Verification

_TEST_MEDIA_ROOT = tempfile.mkdtemp(prefix="toly_moly_test_media_")


def _make_test_image(name="img.png"):
    buffer = io.BytesIO()
    Image.new("RGB", (10, 10), color="blue").save(buffer, format="PNG")
    buffer.seek(0)
    buffer.name = name
    return buffer


@override_settings(MEDIA_ROOT=_TEST_MEDIA_ROOT)
class VerificationEndpointTests(APITestCase):
    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(_TEST_MEDIA_ROOT, ignore_errors=True)

    def setUp(self):
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="TASKER", is_active=True
        )
        self.access = str(RefreshToken.for_user(self.user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")

    def test_status_defaults_to_not_submitted(self):
        response = self.client.get(reverse("verification-status"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["verification_status"], "NOT_SUBMITTED")

    def test_status_requires_authentication(self):
        self.client.credentials()
        response = self.client.get(reverse("verification-status"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_upload_nrc_sets_pending_and_submitted_at(self):
        response = self.client.post(
            reverse("verification-upload-nrc"),
            {
                "nrc_front": _make_test_image("front.png"),
                "nrc_back": _make_test_image("back.png"),
                "date_of_birth": "1995-05-01",
                "permanent_address": "No. 1, Lanmadaw, Yangon",
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["verification_status"], "PENDING")
        self.assertIsNotNone(response.data["submitted_at"])

        verification = Verification.objects.get(user=self.user)
        self.assertEqual(str(verification.date_of_birth), "1995-05-01")
        self.assertEqual(verification.permanent_address, "No. 1, Lanmadaw, Yangon")

    def test_upload_face_sets_pending(self):
        response = self.client.post(
            reverse("verification-upload-face"),
            {"face_image": _make_test_image("face.png")},
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["verification_status"], "PENDING")

    def test_upload_video_does_not_change_status(self):
        video = io.BytesIO(b"fake video bytes")
        video.name = "promo.mp4"
        response = self.client.post(
            reverse("verification-upload-video"), {"promotion_video": video}, format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["verification_status"], "NOT_SUBMITTED")

    def test_upload_nrc_missing_file_returns_400(self):
        response = self.client.post(reverse("verification-upload-nrc"), {}, format="multipart")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
