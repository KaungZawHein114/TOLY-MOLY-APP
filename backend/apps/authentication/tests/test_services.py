from django.test import TestCase
from django.utils import timezone

from apps.authentication.models import PhoneOTP
from apps.authentication.services import (
    DEV_FIXED_OTP_CODE,
    generate_otp_for_phone,
    has_verified_otp,
)


class GenerateOtpForPhoneTests(TestCase):
    def test_creates_fixed_dev_code(self):
        otp = generate_otp_for_phone("09444444444")
        self.assertEqual(otp.code, DEV_FIXED_OTP_CODE)

    def test_sets_five_minute_expiry(self):
        before = timezone.now()
        otp = generate_otp_for_phone("09444444444")
        self.assertGreater(otp.expires_at, before + timezone.timedelta(minutes=4))
        self.assertLess(otp.expires_at, before + timezone.timedelta(minutes=6))

    def test_invalidates_prior_unused_otp(self):
        first = generate_otp_for_phone("09444444444")
        generate_otp_for_phone("09444444444")
        self.assertFalse(PhoneOTP.objects.filter(pk=first.pk).exists())


class HasVerifiedOtpTests(TestCase):
    def test_false_when_no_otp_exists(self):
        self.assertFalse(has_verified_otp("09555555555"))

    def test_false_when_otp_exists_but_unused(self):
        PhoneOTP.objects.create(
            phone_number="09555555555",
            code="12345",
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
        )
        self.assertFalse(has_verified_otp("09555555555"))

    def test_true_when_otp_was_used_recently(self):
        PhoneOTP.objects.create(
            phone_number="09555555555",
            code="12345",
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
            is_used=True,
        )
        self.assertTrue(has_verified_otp("09555555555"))

    def test_false_when_used_otp_is_too_old(self):
        otp = PhoneOTP.objects.create(
            phone_number="09555555555",
            code="12345",
            expires_at=timezone.now() + timezone.timedelta(minutes=5),
            is_used=True,
        )
        PhoneOTP.objects.filter(pk=otp.pk).update(
            created_at=timezone.now() - timezone.timedelta(minutes=61)
        )
        self.assertFalse(has_verified_otp("09555555555"))
