from django.test import TestCase

from apps.profiles.models import ClientProfile, TaskerProfile
from apps.users.models import User


class ProfileModelTests(TestCase):
    def test_client_profile_links_to_user(self):
        user = User.objects.create_user(phone_number="09111111111", password="x", role="CLIENT")
        profile = ClientProfile.objects.create(user=user, name="Mya", gender="Female", age=28)
        self.assertEqual(user.client_profile, profile)

    def test_tasker_profile_links_to_user(self):
        user = User.objects.create_user(phone_number="09222222222", password="x", role="TASKER")
        profile = TaskerProfile.objects.create(user=user, name="Aung", gender="Male", age=34)
        self.assertEqual(user.tasker_profile, profile)
