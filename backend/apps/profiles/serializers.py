from rest_framework import serializers

from apps.profiles.models import ClientProfile, TaskerProfile


class ClientProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClientProfile
        fields = ["name", "gender", "age", "profile_picture"]
        read_only_fields = ["profile_picture"]


class TaskerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskerProfile
        fields = ["name", "gender", "age", "profile_picture", "tier", "trust_score"]
        read_only_fields = ["profile_picture", "tier", "trust_score"]


class ProfilePictureUploadSerializer(serializers.Serializer):
    profile_picture = serializers.ImageField()
