from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.authentication.models import PhoneOTP


class VerifyOtpEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-verify-otp")
        self.phone_number = "09123456789"
        self.otp = PhoneOTP.objects.create(
            phone_number=self.phone_number,
            code="111111",
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
        )

    def test_correct_code_marks_otp_used(self):
        response = self.client.post(
            self.url, {"phone_number": self.phone_number, "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {"phone_verified": True})
        self.otp.refresh_from_db()
        self.assertTrue(self.otp.is_used)

    def test_wrong_code_returns_400_and_increments_attempts(self):
        response = self.client.post(
            self.url, {"phone_number": self.phone_number, "code": "999999"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.otp.refresh_from_db()
        self.assertEqual(self.otp.attempts, 1)

    def test_expired_code_returns_410(self):
        self.otp.expires_at = timezone.now() - timezone.timedelta(minutes=1)
        self.otp.save(update_fields=["expires_at"])
        response = self.client.post(
            self.url, {"phone_number": self.phone_number, "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_410_GONE)

    def test_already_used_code_returns_410(self):
        self.otp.is_used = True
        self.otp.save(update_fields=["is_used"])
        response = self.client.post(
            self.url, {"phone_number": self.phone_number, "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_410_GONE)

    def test_no_otp_for_phone_returns_410(self):
        response = self.client.post(
            self.url, {"phone_number": "09100000000", "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_410_GONE)

    def test_locks_after_five_wrong_attempts(self):
        for _ in range(5):
            self.client.post(
                self.url, {"phone_number": self.phone_number, "code": "000000"}, format="json"
            )
        response = self.client.post(
            self.url, {"phone_number": self.phone_number, "code": "111111"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_423_LOCKED)
