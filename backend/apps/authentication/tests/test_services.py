from django.test import TestCase
from django.utils import timezone

from apps.authentication.models import PhoneOTP
from apps.authentication.services import generate_otp_for_user
from apps.users.models import User


class GenerateOtpForUserTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(phone_number="09444444444", password="x", role="CLIENT")

    def test_creates_six_digit_code(self):
        otp = generate_otp_for_user(self.user)
        self.assertEqual(len(otp.code), 6)
        self.assertTrue(otp.code.isdigit())

    def test_sets_five_minute_expiry(self):
        before = timezone.now()
        otp = generate_otp_for_user(self.user)
        self.assertGreater(otp.expires_at, before + timezone.timedelta(minutes=4))
        self.assertLess(otp.expires_at, before + timezone.timedelta(minutes=6))

    def test_invalidates_prior_unused_otp(self):
        first = generate_otp_for_user(self.user)
        generate_otp_for_user(self.user)
        self.assertFalse(PhoneOTP.objects.filter(pk=first.pk).exists())
