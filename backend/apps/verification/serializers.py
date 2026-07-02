from rest_framework import serializers

from apps.verification.models import Verification


class NrcUploadSerializer(serializers.Serializer):
    nrc_front = serializers.ImageField()
    nrc_back = serializers.ImageField()
    date_of_birth = serializers.DateField(required=False)
    permanent_address = serializers.CharField(max_length=255, required=False, allow_blank=True)


class FaceUploadSerializer(serializers.Serializer):
    face_image = serializers.ImageField()


class VideoUploadSerializer(serializers.Serializer):
    promotion_video = serializers.FileField()


class VerificationStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = Verification
        fields = [
            "verification_status",
            "submitted_at",
            "verified_at",
        ]
