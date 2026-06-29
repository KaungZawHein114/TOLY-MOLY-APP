from django.test import TestCase
from django.utils import timezone

from apps.authentication.models import PhoneOTP
from apps.users.models import User


class PhoneOTPModelTests(TestCase):
    def test_otp_links_to_user(self):
        user = User.objects.create_user(phone_number="09333333333", password="x", role="CLIENT")
        otp = PhoneOTP.objects.create(
            user=user, code="123456", expires_at=timezone.now() + timezone.timedelta(minutes=5)
        )
        self.assertEqual(otp.user, user)
        self.assertFalse(otp.is_used)
        self.assertEqual(otp.attempts, 0)
