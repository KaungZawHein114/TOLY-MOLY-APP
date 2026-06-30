import re

from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from rest_framework import serializers

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

    # phone_already_registered / otp_not_verified are checked in the view,
    # not here — a dict raised from a serializer's validate() gets each
    # value wrapped in a list by DRF, which breaks the flat
    # {"detail": ..., "code": ...} shape the rest of this API uses for
    # business-logic errors (see RegisterView).
    @transaction.atomic
    def create(self, validated_data):
        user = User.objects.create_user(
            phone_number=validated_data["phone_number"],
            password=validated_data["password"],
            role=validated_data["role"],
        )
        # Phone ownership was already proven via verify-otp before this
        # call is reachable (RegisterView checks has_verified_otp) — this
        # is the moment the account actually comes into existence, fully
        # formed, so it goes straight to active+verified.
        user.is_active = True
        user.is_phone_verified = True
        user.save(update_fields=["is_active", "is_phone_verified"])

        profile_model = ClientProfile if validated_data["role"] == "CLIENT" else TaskerProfile
        profile_model.objects.create(
            user=user,
            name=validated_data["name"],
            gender=validated_data["gender"],
            age=validated_data["age"],
        )
        return user


class SendOtpSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)

    def validate_phone_number(self, value):
        if not PHONE_REGEX.match(value):
            raise serializers.ValidationError("Enter a valid phone number (e.g. 09123456789).")
        return value


class VerifyOtpSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)
    code = serializers.CharField(max_length=6)


class LoginSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True)
