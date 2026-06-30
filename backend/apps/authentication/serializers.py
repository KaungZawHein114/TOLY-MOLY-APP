import re

from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from rest_framework import serializers
from rest_framework.exceptions import NotFound

from apps.profiles.models import ClientProfile, TaskerProfile
from apps.users.models import User

PHONE_REGEX = re.compile(r"^09\d{7,9}$")


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=150)
    phone_number = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True)
    gender = serializers.CharField(max_length=10)
    age = serializers.IntegerField(min_value=16, max_value=100)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES)

    def validate_phone_number(self, value):
        if not PHONE_REGEX.match(value):
            raise serializers.ValidationError("Enter a valid phone number (e.g. 09123456789).")
        return value

    def validate_password(self, value):
        validate_password(value)
        return value

    @transaction.atomic
    def create(self, validated_data):
        user = User.objects.create_user(
            phone_number=validated_data["phone_number"],
            password=validated_data["password"],
            role=validated_data["role"],
        )
        profile_model = ClientProfile if validated_data["role"] == "CLIENT" else TaskerProfile
        profile_model.objects.create(
            user=user,
            name=validated_data["name"],
            gender=validated_data["gender"],
            age=validated_data["age"],
        )
        # No auto-generated OTP here — the client always calls send-otp
        # explicitly right after register, and a redundant auto-send here
        # used to race with that call's 30s resend cooldown.
        return user


class SendOtpSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)

    def validate_phone_number(self, value):
        if not User.objects.filter(phone_number=value).exists():
            raise NotFound("No account found for this phone number.")
        return value


class VerifyOtpSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)
    code = serializers.CharField(max_length=6)


class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True)
