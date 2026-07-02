from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from apps.taskers.models import Skill
from apps.users.models import User


class SkillEndpointTests(APITestCase):
    def setUp(self):
        self.list_url = reverse("tasker-skills")
        self.tasker = User.objects.create_user(
            phone_number="09123456789", password="x", role="TASKER", is_active=True
        )
        self.client_user = User.objects.create_user(
            phone_number="09199999999", password="x", role="CLIENT", is_active=True
        )
        self.tasker_access = str(RefreshToken.for_user(self.tasker).access_token)
        self.client_access = str(RefreshToken.for_user(self.client_user).access_token)

    def _as_tasker(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.tasker_access}")

    def _as_client(self):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.client_access}")

    def test_client_role_cannot_access_skills(self):
        self._as_client()
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_create_skill(self):
        self._as_tasker()
        response = self.client.post(
            self.list_url, {"skill_name": "Plumbing", "experience_years": 5}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Skill.objects.filter(tasker=self.tasker, skill_name="Plumbing").exists())

    def test_list_skills_returns_only_own_skills(self):
        Skill.objects.create(tasker=self.tasker, skill_name="Plumbing", experience_years=5)
        other_tasker = User.objects.create_user(
            phone_number="09177777777", password="x", role="TASKER", is_active=True
        )
        Skill.objects.create(tasker=other_tasker, skill_name="Electrical", experience_years=3)

        self._as_tasker()
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["skill_name"], "Plumbing")

    def test_update_own_skill(self):
        skill = Skill.objects.create(tasker=self.tasker, skill_name="Plumbing", experience_years=5)
        self._as_tasker()
        response = self.client.put(
            reverse("tasker-skill-detail", args=[skill.id]),
            {"experience_years": 7},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        skill.refresh_from_db()
        self.assertEqual(skill.experience_years, 7)

    def test_cannot_update_another_taskers_skill(self):
        other_tasker = User.objects.create_user(
            phone_number="09177777777", password="x", role="TASKER", is_active=True
        )
        skill = Skill.objects.create(tasker=other_tasker, skill_name="Electrical", experience_years=3)
        self._as_tasker()
        response = self.client.put(
            reverse("tasker-skill-detail", args=[skill.id]), {"experience_years": 9}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_own_skill(self):
        skill = Skill.objects.create(tasker=self.tasker, skill_name="Plumbing", experience_years=5)
        self._as_tasker()
        response = self.client.delete(reverse("tasker-skill-detail", args=[skill.id]))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Skill.objects.filter(pk=skill.id).exists())
