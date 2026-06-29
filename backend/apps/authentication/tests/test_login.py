from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.users.models import User


class LoginEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-login")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="StrongPass123", role="CLIENT"
        )

    def test_login_rejects_unverified_account(self):
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "password": "StrongPass123"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(response.data.get("code"), "account_not_verified")

    def test_login_succeeds_for_active_user(self):
        self.user.is_active = True
        self.user.save(update_fields=["is_active"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "password": "StrongPass123"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access_token", response.data)
        self.assertIn("refresh_token", response.data)

    def test_login_rejects_wrong_password(self):
        self.user.is_active = True
        self.user.save(update_fields=["is_active"])
        response = self.client.post(
            self.url, {"phone_number": "09123456789", "password": "wrong"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_login_rejects_unknown_phone(self):
        response = self.client.post(
            self.url, {"phone_number": "09199999999", "password": "whatever"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
