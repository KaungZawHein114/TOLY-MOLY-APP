from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.profiles.serializers import (
    ClientProfileSerializer,
    ProfilePictureUploadSerializer,
    TaskerProfileSerializer,
)


def _profile_and_serializer_class(user):
    if user.role == "CLIENT":
        return user.client_profile, ClientProfileSerializer
    return user.tasker_profile, TaskerProfileSerializer


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, serializer_class = _profile_and_serializer_class(request.user)
        return Response(serializer_class(profile).data, status=status.HTTP_200_OK)

    def put(self, request):
        profile, serializer_class = _profile_and_serializer_class(request.user)
        serializer = serializer_class(profile, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class ProfilePictureUploadView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = ProfilePictureUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        profile, _ = _profile_and_serializer_class(request.user)
        profile.profile_picture = serializer.validated_data["profile_picture"]
        profile.save(update_fields=["profile_picture"])
        return Response({"profile_picture": profile.profile_picture.url}, status=status.HTTP_200_OK)
