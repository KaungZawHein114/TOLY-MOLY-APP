from django.db import models

from apps.users.models import User


class Verification(models.Model):
    STATUS_NOT_SUBMITTED = "NOT_SUBMITTED"
    STATUS_PENDING = "PENDING"
    STATUS_APPROVED = "APPROVED"
    STATUS_REJECTED = "REJECTED"
    STATUS_CHOICES = [
        (STATUS_NOT_SUBMITTED, "Not Submitted"),
        (STATUS_PENDING, "Pending"),
        (STATUS_APPROVED, "Approved"),
        (STATUS_REJECTED, "Rejected"),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="verification")
    nrc_front = models.ImageField(upload_to="verification/nrc/", blank=True, null=True)
    nrc_back = models.ImageField(upload_to="verification/nrc/", blank=True, null=True)
    face_image = models.ImageField(upload_to="verification/face/", blank=True, null=True)
    promotion_video = models.FileField(upload_to="verification/video/", blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    permanent_address = models.CharField(max_length=255, blank=True)
    verification_status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default=STATUS_NOT_SUBMITTED
    )
    submitted_at = models.DateTimeField(blank=True, null=True)
    verified_at = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"Verification for {self.user.phone_number} ({self.verification_status})"
