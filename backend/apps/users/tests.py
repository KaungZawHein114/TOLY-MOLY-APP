from django.test import TestCase

from apps.users.models import User


class UserModelTests(TestCase):
    def test_create_user_sets_expected_defaults(self):
        user = User.objects.create_user(
            phone_number="09123456789", password="StrongPass123", role="CLIENT"
        )
        self.assertEqual(user.phone_number, "09123456789")
        self.assertEqual(user.role, "CLIENT")
        self.assertEqual(user.status, "UNVERIFIED")
        self.assertFalse(user.is_phone_verified)
        self.assertFalse(user.is_active)
        self.assertTrue(user.check_password("StrongPass123"))

    def test_create_user_requires_phone_number(self):
        with self.assertRaises(ValueError):
            User.objects.create_user(phone_number="", password="x", role="CLIENT")

    def test_phone_number_is_unique(self):
        User.objects.create_user(phone_number="09123456789", password="x", role="CLIENT")
        with self.assertRaises(Exception):
            User.objects.create_user(phone_number="09123456789", password="y", role="TASKER")
