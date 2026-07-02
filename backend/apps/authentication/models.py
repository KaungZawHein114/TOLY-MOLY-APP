from django.db import models


class PhoneOTP(models.Model):
    """Keyed by raw phone_number, not a User FK — OTP verification has to
    work before any account exists, since registration is now the very
    last step of onboarding (after rules agreement), not the first."""

    phone_number = models.CharField(max_length=20, db_index=True)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveSmallIntegerField(default=0)

    def __str__(self):
        return f"OTP for {self.phone_number}"
