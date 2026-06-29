from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.authentication.models import PhoneOTP
from apps.users.models import User


class VerifyOtpEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-verify-otp")
        self.user = User.objects.create_user(phone_number="09123456789", password="x", role="CLIENT")
        self.otp = PhoneOTP.objects.create(
            user=self.user, code="111111", expires_at=timezone.now() + timezone.timedelta(minutes=5)
        )

    def test_correct_code_activates_user_and_returns_tokens(self):
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access_token", response.data)
        self.assertIn("refresh_token", response.data)
        self.assertEqual(response.data["user"]["phone_number"], "09123456789")

        self.user.refresh_from_db()
        self.assertTrue(self.user.is_active)
        self.assertTrue(self.user.is_phone_verified)
        self.otp.refresh_from_db()
        self.assertTrue(self.otp.is_used)

    def test_wrong_code_returns_400_and_increments_attempts(self):
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "999999"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.otp.refresh_from_db()
        self.assertEqual(self.otp.attempts, 1)

    def test_expired_code_returns_410(self):
        self.otp.expires_at = timezone.now() - timezone.timedelta(minutes=1)
        self.otp.save(update_fields=["expires_at"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_410_GONE)

    def test_already_used_code_returns_410(self):
        self.otp.is_used = True
        self.otp.save(update_fields=["is_used"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_410_GONE)

    def test_locks_after_five_wrong_attempts(self):
        for _ in range(5):
            self.client.post(
                self.url, {"phone_number": "09123456789", "code": "000000"}, format="json"
            )
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_423_LOCKED)
