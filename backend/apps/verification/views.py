from django.utils import timezone
from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.verification.models import Verification
from apps.verification.serializers import (
    FaceUploadSerializer,
    NrcUploadSerializer,
    VerificationStatusSerializer,
    VideoUploadSerializer,
)


def _mark_submitted(verification):
    if verification.submitted_at is None:
        verification.submitted_at = timezone.now()
    if verification.verification_status == Verification.STATUS_NOT_SUBMITTED:
        verification.verification_status = Verification.STATUS_PENDING


class UploadNrcView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = NrcUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        verification, _ = Verification.objects.get_or_create(user=request.user)
        verification.nrc_front = serializer.validated_data["nrc_front"]
        verification.nrc_back = serializer.validated_data["nrc_back"]
        if "date_of_birth" in serializer.validated_data:
            verification.date_of_birth = serializer.validated_data["date_of_birth"]
        if "permanent_address" in serializer.validated_data:
            verification.permanent_address = serializer.validated_data["permanent_address"]
        _mark_submitted(verification)
        verification.save()

        return Response(VerificationStatusSerializer(verification).data, status=status.HTTP_200_OK)


class UploadFaceView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = FaceUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        verification, _ = Verification.objects.get_or_create(user=request.user)
        verification.face_image = serializer.validated_data["face_image"]
        _mark_submitted(verification)
        verification.save()

        return Response(VerificationStatusSerializer(verification).data, status=status.HTTP_200_OK)


class UploadVideoView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = VideoUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        verification, _ = Verification.objects.get_or_create(user=request.user)
        verification.promotion_video = serializer.validated_data["promotion_video"]
        verification.save()

        return Response(VerificationStatusSerializer(verification).data, status=status.HTTP_200_OK)


class VerificationStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        verification, _ = Verification.objects.get_or_create(user=request.user)
        return Response(VerificationStatusSerializer(verification).data, status=status.HTTP_200_OK)
