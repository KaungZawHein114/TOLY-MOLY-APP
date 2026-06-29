import random

from django.utils import timezone

from apps.authentication.models import PhoneOTP

OTP_LIFETIME_MINUTES = 5
MAX_OTP_ATTEMPTS = 5


def generate_otp_for_user(user):
    PhoneOTP.objects.filter(user=user, is_used=False).delete()
    code = f"{random.randint(0, 999999):06d}"
    return PhoneOTP.objects.create(
        user=user,
        code=code,
        expires_at=timezone.now() + timezone.timedelta(minutes=OTP_LIFETIME_MINUTES),
    )
