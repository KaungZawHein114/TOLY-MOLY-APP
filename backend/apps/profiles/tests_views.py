import io
import shutil
import tempfile

from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from PIL import Image
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.authentication.models import PhoneOTP
from apps.profiles.models import ClientProfile
from apps.users.models import User

_TEST_MEDIA_ROOT = tempfile.mkdtemp(prefix="toly_moly_test_media_")


def _make_test_image():
    buffer = io.BytesIO()
    Image.new("RGB", (10, 10), color="red").save(buffer, format="PNG")
    buffer.seek(0)
    buffer.name = "avatar.png"
    return buffer


@override_settings(MEDIA_ROOT=_TEST_MEDIA_ROOT)
class ProfileEndpointTests(APITestCase):
    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(_TEST_MEDIA_ROOT, ignore_errors=True)

    def setUp(self):
        self.url = reverse("profile")
        self.upload_url = reverse("profile-upload-picture")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="CLIENT", is_active=True
        )
        self.profile = ClientProfile.objects.create(user=self.user, name="Mya", gender="Female", age=28)
        self.access = str(RefreshToken.for_user(self.user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")

    def test_get_profile_requires_authentication(self):
        self.client.credentials()
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_get_profile_returns_current_data(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Mya")
        self.assertEqual(response.data["age"], 28)

    def test_put_profile_updates_fields(self):
        response = self.client.put(self.url, {"name": "Mya Mya", "age": 29}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.profile.refresh_from_db()
        self.assertEqual(self.profile.name, "Mya Mya")
        self.assertEqual(self.profile.age, 29)
        self.assertEqual(self.profile.gender, "Female")  # untouched field stays as-is

    def test_upload_picture_sets_profile_picture(self):
        response = self.client.post(
            self.upload_url, {"profile_picture": _make_test_image()}, format="multipart"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.profile.refresh_from_db()
        self.assertTrue(bool(self.profile.profile_picture))
        self.assertIn("profile_picture", response.data)

    def test_get_profile_includes_phone_and_status(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["phone_number"], "09123456789")
        self.assertEqual(response.data["status"], "UNVERIFIED")


class PhoneChangeEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("profile-phone")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="TASKER", is_active=True
        )
        self.access = str(RefreshToken.for_user(self.user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")

    def _verify_otp_for(self, phone_number):
        PhoneOTP.objects.create(
            phone_number=phone_number,
            code="12345",
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
            is_used=True,
        )

    def test_requires_authentication(self):
        self.client.credentials()
        response = self.client.put(self.url, {"phone_number": "09999999999"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_rejects_change_without_verified_otp(self):
        response = self.client.put(self.url, {"phone_number": "09999999999"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["code"], "otp_not_verified")

    def test_rejects_number_already_registered_to_another_user(self):
        User.objects.create_user(phone_number="09999999999", password="x", role="CLIENT", is_active=True)
        self._verify_otp_for("09999999999")
        response = self.client.put(self.url, {"phone_number": "09999999999"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["code"], "phone_already_registered")

    def test_updates_phone_after_verified_otp(self):
        self._verify_otp_for("09999999999")
        response = self.client.put(self.url, {"phone_number": "09999999999"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.phone_number, "09999999999")
