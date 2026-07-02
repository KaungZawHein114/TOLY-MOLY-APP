from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.authentication.models import PhoneOTP
from apps.profiles.models import ClientProfile, TaskerProfile
from apps.users.models import User


class RegisterEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-register")
        self.valid_payload = {
            "name": "Mya Mya",
            "phone_number": "09123456789",
            "password": "StrongPass123",
            "gender": "Female",
            "age": 28,
            "role": "CLIENT",
        }

    def _mark_phone_verified(self, phone_number):
        PhoneOTP.objects.create(
            phone_number=phone_number,
            code="12345",
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
            is_used=True,
        )

    def test_register_rejected_without_prior_otp_verification(self):
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("code"), "otp_not_verified")
        self.assertFalse(User.objects.filter(phone_number="09123456789").exists())

    def test_register_creates_active_verified_user_and_profile_and_returns_tokens(self):
        self._mark_phone_verified("09123456789")
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access_token", response.data)
        self.assertIn("refresh_token", response.data)
        self.assertEqual(response.data["user"]["phone_number"], "09123456789")

        user = User.objects.get(phone_number="09123456789")
        self.assertTrue(user.is_active)
        self.assertTrue(user.is_phone_verified)
        self.assertEqual(user.status, "UNVERIFIED")  # marketplace KYC status, separate concern
        self.assertTrue(ClientProfile.objects.filter(user=user, name="Mya Mya").exists())

    def test_register_creates_tasker_profile_for_tasker_role(self):
        self._mark_phone_verified("09199999999")
        payload = {**self.valid_payload, "phone_number": "09199999999", "role": "TASKER"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(phone_number="09199999999")
        self.assertTrue(TaskerProfile.objects.filter(user=user).exists())
        self.assertFalse(ClientProfile.objects.filter(user=user).exists())

    def test_duplicate_phone_number_rejected(self):
        self._mark_phone_verified("09123456789")
        self.client.post(self.url, self.valid_payload, format="json")
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("code"), "phone_already_registered")

    def test_weak_password_rejected(self):
        self._mark_phone_verified("09188888888")
        payload = {**self.valid_payload, "phone_number": "09188888888", "password": "123"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("password", response.data)

    def test_invalid_phone_format_rejected(self):
        response = self.client.post(self.url, {**self.valid_payload, "phone_number": "12345"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_age_out_of_bounds_rejected(self):
        self._mark_phone_verified("09177777777")
        payload = {**self.valid_payload, "phone_number": "09177777777", "age": 10}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("age", response.data)
