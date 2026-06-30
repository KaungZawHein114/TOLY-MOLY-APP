from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

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

    def test_register_creates_inactive_user_and_profile(self):
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["phone_number"], "09123456789")
        self.assertEqual(response.data["role"], "CLIENT")

        user = User.objects.get(phone_number="09123456789")
        self.assertFalse(user.is_active)
        self.assertEqual(user.status, "UNVERIFIED")
        self.assertTrue(ClientProfile.objects.filter(user=user, name="Mya Mya").exists())

    def test_register_creates_tasker_profile_for_tasker_role(self):
        payload = {**self.valid_payload, "phone_number": "09199999999", "role": "TASKER"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(phone_number="09199999999")
        self.assertTrue(TaskerProfile.objects.filter(user=user).exists())
        self.assertFalse(ClientProfile.objects.filter(user=user).exists())

    def test_register_does_not_auto_generate_an_otp(self):
        # The client always calls send-otp explicitly right after register;
        # an auto-generated OTP here would race with that call's resend
        # cooldown and could leave the OTP screen with nothing to enter.
        self.client.post(self.url, self.valid_payload, format="json")
        user = User.objects.get(phone_number="09123456789")
        self.assertFalse(user.otps.exists())

    def test_duplicate_phone_number_rejected(self):
        self.client.post(self.url, self.valid_payload, format="json")
        response = self.client.post(self.url, self.valid_payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data.get("code"), "phone_already_registered")

    def test_weak_password_rejected(self):
        payload = {**self.valid_payload, "phone_number": "09188888888", "password": "123"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("password", response.data)

    def test_invalid_phone_format_rejected(self):
        payload = {**self.valid_payload, "phone_number": "12345"}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("phone_number", response.data)

    def test_age_out_of_bounds_rejected(self):
        payload = {**self.valid_payload, "phone_number": "09177777777", "age": 10}
        response = self.client.post(self.url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("age", response.data)
