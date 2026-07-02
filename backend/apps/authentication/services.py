from django.utils import timezone

from apps.authentication.models import PhoneOTP

OTP_LIFETIME_MINUTES = 5
MAX_OTP_ATTEMPTS = 5

# Dev-mode only: every OTP is this fixed code instead of a random one, so
# testing the register/login flow doesn't require reading dev_otp_code out
# of the API response each time. Swap this back to a random 6-digit code
# (see git history) once a real SMS gateway replaces the dev-mode flow.
DEV_FIXED_OTP_CODE = "12345"


OTP_VERIFIED_WINDOW_MINUTES = 60


def generate_otp_for_phone(phone_number):
    PhoneOTP.objects.filter(phone_number=phone_number, is_used=False).delete()
    return PhoneOTP.objects.create(
        phone_number=phone_number,
        code=DEV_FIXED_OTP_CODE,
        expires_at=timezone.now() + timezone.timedelta(minutes=OTP_LIFETIME_MINUTES),
    )


def has_verified_otp(phone_number):
    """True if this phone completed verify-otp recently enough that
    register (the final onboarding step) can trust it without asking the
    user to re-verify."""
    cutoff = timezone.now() - timezone.timedelta(minutes=OTP_VERIFIED_WINDOW_MINUTES)
    return PhoneOTP.objects.filter(
        phone_number=phone_number, is_used=True, created_at__gte=cutoff
    ).exists()
