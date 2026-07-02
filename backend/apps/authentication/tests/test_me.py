from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.profiles.models import ClientProfile
from apps.users.models import User


class MeEndpointTests(APITestCase):
    def setUp(self):
        self.url = reverse("auth-me")
        self.user = User.objects.create_user(
            phone_number="09123456789", password="x", role="CLIENT", is_active=True, is_phone_verified=True
        )
        ClientProfile.objects.create(user=self.user, name="Mya Mya", gender="Female", age=28)
        self.access = str(RefreshToken.for_user(self.user).access_token)

    def test_me_requires_authentication(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_returns_user_and_profile(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.access}")
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["phone_number"], "09123456789")
        self.assertEqual(response.data["profile"]["name"], "Mya Mya")
        self.assertEqual(response.data["profile"]["age"], 28)
