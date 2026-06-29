from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User


class RefreshEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-refresh")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="CLIENT", is_active=True
        )
        self.refresh = RefreshToken.for_user(self.user)

    def test_valid_refresh_returns_new_access_token(self):
        response = self.client.post(self.url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access_token", response.data)

    def test_invalid_refresh_token_returns_401(self):
        response = self.client.post(self.url, {"refresh_token": "not-a-real-token"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
