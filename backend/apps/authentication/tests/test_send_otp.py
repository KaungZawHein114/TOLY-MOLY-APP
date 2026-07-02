from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.authentication.models import PhoneOTP
from apps.users.models import User


class SendOtpEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-send-otp")

    def test_send_otp_returns_dev_code_for_unregistered_phone(self):
        response = self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["otp_sent"])
        otp = PhoneOTP.objects.get(phone_number="09123456789", is_used=False)
        self.assertEqual(response.data["dev_otp_code"], otp.code)

    def test_already_registered_phone_rejected(self):
        User.objects.create_user(phone_number="09123456789", password="x", role="CLIENT")
        response = self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("code"), "phone_already_registered")

    def test_invalid_phone_format_rejected(self):
        response = self.client.post(self.url, {"phone_number": "12345"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cooldown_blocks_immediate_resend(self):
        self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        response = self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertEqual(response.data.get("code"), "otp_cooldown")

    def test_resend_allowed_after_cooldown(self):
        self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        otp = PhoneOTP.objects.get(phone_number="09123456789", is_used=False)
        otp.created_at = timezone.now() - timezone.timedelta(seconds=31)
        otp.save(update_fields=["created_at"])
        response = self.client.post(self.url, {"phone_number": "09123456789"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
