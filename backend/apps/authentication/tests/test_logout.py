from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User


class LogoutEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-logout")
        self.refresh_url = reverse("auth-refresh")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="CLIENT", is_active=True
        )
        self.refresh = RefreshToken.for_user(self.user)
        self.access = str(self.refresh.access_token)

    def test_logout_requires_authentication(self):
        response = self.client.post(self.url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_logout_blacklists_refresh_token(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")
        response = self.client.post(self.url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        refresh_response = self.client.post(self.refresh_url, {"refresh_token": str(self.refresh)}, format="json")
        self.assertEqual(refresh_response.status_code, status.HTTP_401_UNAUTHORIZED)
