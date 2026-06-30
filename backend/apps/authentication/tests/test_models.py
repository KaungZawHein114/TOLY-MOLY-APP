from django.test import TestCase
from django.utils import timezone

from apps.authentication.models import PhoneOTP


class PhoneOTPModelTests(TestCase):
    def test_otp_is_keyed_by_phone_number(self):
        otp = PhoneOTP.objects.create(
            phone_number="09333333333",
            code="123456",
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
        )
        self.assertEqual(otp.phone_number, "09333333333")
        self.assertFalse(otp.is_used)
        self.assertEqual(otp.attempts, 0)
