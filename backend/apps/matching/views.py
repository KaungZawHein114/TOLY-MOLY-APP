from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.matching.serializers import ClassifyCategorySerializer
from apps.matching.services import MatchingServiceUnavailable, classify_category


class ClassifyCategoryView(APIView):
    """POST /api/matching/classify-category — the AI Tasker Finder classifier,
    a separate agent from the App Assistant (apps.assistant) and the AI Task
    Assistant (apps.tasks).

    Request:  {"message": "my sink is leaking"}
    Response: {"category": "Plumber", "confidence": 0.95, "problem": "sink is leaking"}

    The response is additive-only by contract: later versions may add keys
    (ranked tasker ids, GPS radius, demand signals) but never change or remove
    these three, so the Flutter client keeps working untouched.

    No auth for now, matching the other two AI endpoints: classification is not
    user-specific yet. TODO(security): add JWT + per-user context once results
    become personalized.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ClassifyCategorySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            result = classify_category(serializer.validated_data["message"])
        except MatchingServiceUnavailable as exc:
            return Response(
                {"detail": str(exc), "code": "matching_unavailable"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response(result, status=status.HTTP_200_OK)
