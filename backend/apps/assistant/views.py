from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.assistant.serializers import AssistantChatSerializer
from apps.assistant.services import AssistantServiceUnavailable, chat


class AssistantChatView(APIView):
    """POST /api/assistant/chat — the App Assistant (product-help guide),
    a separate agent from the Task Posting AI Conversation in apps.tasks.

    No auth for now (product decision, not an oversight): this assistant
    answers general "how do I use the app" questions and isn't user-specific
    yet. TODO(security): add JWT + per-user context once personalization is
    needed.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = AssistantChatSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        history = [
            {"role": turn["role"], "content": turn["content"]} for turn in data["history"]
        ]
        try:
            result = chat(data["message"], history)
        except AssistantServiceUnavailable as exc:
            return Response(
                {"detail": str(exc), "code": "assistant_unavailable"},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        return Response(result, status=status.HTTP_200_OK)
