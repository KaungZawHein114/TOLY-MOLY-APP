from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.tasks.models import Task
from apps.tasks.permissions import IsClient
from apps.tasks.serializers import (
    PUBLISH_REQUIRED_FIELDS,
    AnalyzeTaskSerializer,
    BudgetOptionsSerializer,
    ExtractTaskSerializer,
    PublishTaskSerializer,
    TaskSerializer,
)
from apps.tasks.services import (
    AIServiceUnavailable,
    analyze_task,
    compute_budget_options,
    extract_task,
    transcribe_audio,
)


def _ai_unavailable_response(exc):
    return Response(
        {"detail": str(exc), "code": "ai_unavailable"},
        status=status.HTTP_503_SERVICE_UNAVAILABLE,
    )


class TranscribeAudioView(APIView):
    permission_classes = [IsAuthenticated, IsClient]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        audio = request.FILES.get("audio")
        if not audio:
            return Response(
                {"detail": "audio file is required.", "code": "audio_required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            text = transcribe_audio(
                audio.read(), filename=audio.name or "audio.m4a", content_type=audio.content_type or "audio/m4a"
            )
        except AIServiceUnavailable as exc:
            return _ai_unavailable_response(exc)
        return Response({"text": text}, status=status.HTTP_200_OK)


class AnalyzeTaskView(APIView):
    permission_classes = [IsAuthenticated, IsClient]

    def post(self, request):
        serializer = AnalyzeTaskSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            result = analyze_task(data["message"], data["history"], data["known_fields"])
        except AIServiceUnavailable as exc:
            return _ai_unavailable_response(exc)
        return Response(result, status=status.HTTP_200_OK)


class ExtractTaskView(APIView):
    """One-shot voice/text task extraction — see services.extract_task.
    Client dictates once; this returns every field the AI could pull out,
    and the app shows the rest as "Not given" on the review screen."""

    permission_classes = [IsAuthenticated, IsClient]

    def post(self, request):
        serializer = ExtractTaskSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            result = extract_task(serializer.validated_data["transcript"])
        except AIServiceUnavailable as exc:
            return _ai_unavailable_response(exc)
        return Response(result, status=status.HTTP_200_OK)


class BudgetOptionsView(APIView):
    permission_classes = [IsAuthenticated, IsClient]

    def post(self, request):
        serializer = BudgetOptionsSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        options = compute_budget_options(
            serializer.validated_data["category"], serializer.validated_data["urgency"]
        )
        return Response(options, status=status.HTTP_200_OK)


class TaskListCreateView(APIView):
    """GET: the task board — every pending task (any authenticated user,
    client or tasker, can browse it). POST: publish (client only)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.query_params.get("mine") == "true":
            tasks = Task.objects.filter(client=request.user)
        else:
            tasks = Task.objects.filter(status=Task.STATUS_PENDING)
        return Response(TaskSerializer(tasks, many=True).data, status=status.HTTP_200_OK)

    def post(self, request):
        if request.user.role != "CLIENT":
            return Response(
                {"detail": "Only client accounts can post tasks.", "code": "not_a_client"},
                status=status.HTTP_403_FORBIDDEN,
            )

        missing = [field for field in PUBLISH_REQUIRED_FIELDS if not request.data.get(field)]
        if missing:
            return Response(
                {"detail": f"Missing required field(s): {', '.join(missing)}.", "code": "incomplete_task"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = PublishTaskSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        task = serializer.save(client=request.user, status=Task.STATUS_PENDING)
        return Response(TaskSerializer(task).data, status=status.HTTP_201_CREATED)


class TaskDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        task = Task.objects.filter(pk=pk).first()
        if not task:
            return Response(
                {"detail": "Task not found.", "code": "task_not_found"}, status=status.HTTP_404_NOT_FOUND
            )
        return Response(TaskSerializer(task).data, status=status.HTTP_200_OK)
