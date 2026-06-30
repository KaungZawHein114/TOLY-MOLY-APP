from django.utils import timezone

from apps.authentication.models import PhoneOTP

OTP_LIFETIME_MINUTES = 5
MAX_OTP_ATTEMPTS = 5

# Dev-mode only: every OTP is this fixed code instead of a random one, so
# testing the register/login flow doesn't require reading dev_otp_code out
# of the API response each time. Swap this back to a random 6-digit code
# (see git history) once a real SMS gateway replaces the dev-mode flow.
DEV_FIXED_OTP_CODE = "12345"


def generate_otp_for_user(user):
    PhoneOTP.objects.filter(user=user, is_used=False).delete()
    return PhoneOTP.objects.create(
        user=user,
        code=DEV_FIXED_OTP_CODE,
        expires_at=timezone.now() + timezone.timedelta(minutes=OTP_LIFETIME_MINUTES),
    )
