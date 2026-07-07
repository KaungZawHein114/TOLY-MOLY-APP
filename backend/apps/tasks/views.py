from rest_framework import status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.tasks.models import Booking, Task
from apps.tasks.permissions import IsClient, IsTasker
from apps.tasks.serializers import (
    PUBLISH_REQUIRED_FIELDS,
    AnalyzeTaskSerializer,
    BookingSerializer,
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


# ─────────────────────────────────────────────────────────────────────────────
# Booking lifecycle views — check-in / check-out flow
# ─────────────────────────────────────────────────────────────────────────────

def _get_booking_or_404(pk):
    """Return (booking, None) or (None, 404 Response)."""
    booking = Booking.objects.select_related("worker", "client").filter(pk=pk).first()
    if not booking:
        return None, Response(
            {"detail": "Booking not found.", "code": "booking_not_found"},
            status=status.HTTP_404_NOT_FOUND,
        )
    return booking, None


def _invalid_transition(current, action):
    return Response(
        {
            "detail": f"Cannot perform '{action}' from status '{current}'.",
            "code": "invalid_transition",
        },
        status=status.HTTP_409_CONFLICT,
    )


class WorkerCheckinView(APIView):
    """POST /bookings/{id}/worker-checkin/ — worker signals arrival."""

    permission_classes = [IsAuthenticated, IsTasker]

    def post(self, request, pk):
        booking, err = _get_booking_or_404(pk)
        if err:
            return err
        if booking.worker_id != request.user.id:
            return Response(
                {"detail": "You are not the worker for this booking.", "code": "wrong_worker"},
                status=status.HTTP_403_FORBIDDEN,
            )
        if booking.status not in Booking.VALID_CHECKIN_FROM:
            return _invalid_transition(booking.status, "worker-checkin")
        booking.worker_checkin()
        return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)


class ClientConfirmCheckinView(APIView):
    """POST /bookings/{id}/client-confirm-checkin/ — client accepts worker arrival."""

    permission_classes = [IsAuthenticated, IsClient]

    def post(self, request, pk):
        booking, err = _get_booking_or_404(pk)
        if err:
            return err
        if booking.client_id != request.user.id:
            return Response(
                {"detail": "You are not the client for this booking.", "code": "wrong_client"},
                status=status.HTTP_403_FORBIDDEN,
            )
        if booking.status not in Booking.VALID_CLIENT_CONFIRM_CHECKIN_FROM:
            return _invalid_transition(booking.status, "client-confirm-checkin")
        booking.client_confirm_checkin()
        return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)


class ClientRejectCheckinView(APIView):
    """POST /bookings/{id}/client-reject-checkin/ — client disputes worker arrival."""

    permission_classes = [IsAuthenticated, IsClient]

    def post(self, request, pk):
        booking, err = _get_booking_or_404(pk)
        if err:
            return err
        if booking.client_id != request.user.id:
            return Response(
                {"detail": "You are not the client for this booking.", "code": "wrong_client"},
                status=status.HTTP_403_FORBIDDEN,
            )
        if booking.status not in Booking.VALID_CLIENT_REJECT_CHECKIN_FROM:
            return _invalid_transition(booking.status, "client-reject-checkin")
        booking.client_reject_checkin()
        return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)


class WorkerCheckoutView(APIView):
    """POST /bookings/{id}/worker-checkout/ — worker signals job completion."""

    permission_classes = [IsAuthenticated, IsTasker]

    def post(self, request, pk):
        booking, err = _get_booking_or_404(pk)
        if err:
            return err
        if booking.worker_id != request.user.id:
            return Response(
                {"detail": "You are not the worker for this booking.", "code": "wrong_worker"},
                status=status.HTTP_403_FORBIDDEN,
            )
        if booking.status not in Booking.VALID_CHECKOUT_FROM:
            return _invalid_transition(booking.status, "worker-checkout")
        booking.worker_checkout()
        return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)


class ClientConfirmCheckoutView(APIView):
    """POST /bookings/{id}/client-confirm-checkout/ — client confirms job completion."""

    permission_classes = [IsAuthenticated, IsClient]

    def post(self, request, pk):
        booking, err = _get_booking_or_404(pk)
        if err:
            return err
        if booking.client_id != request.user.id:
            return Response(
                {"detail": "You are not the client for this booking.", "code": "wrong_client"},
                status=status.HTTP_403_FORBIDDEN,
            )
        if booking.status not in Booking.VALID_CLIENT_CONFIRM_CHECKOUT_FROM:
            return _invalid_transition(booking.status, "client-confirm-checkout")
        booking.client_confirm_checkout()
        return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)


class ClientReportCheckoutIssueView(APIView):
    """POST /bookings/{id}/client-report-checkout-issue/ — client disputes completion."""

    permission_classes = [IsAuthenticated, IsClient]

    def post(self, request, pk):
        booking, err = _get_booking_or_404(pk)
        if err:
            return err
        if booking.client_id != request.user.id:
            return Response(
                {"detail": "You are not the client for this booking.", "code": "wrong_client"},
                status=status.HTTP_403_FORBIDDEN,
            )
        if booking.status not in Booking.VALID_CLIENT_REPORT_ISSUE_FROM:
            return _invalid_transition(booking.status, "client-report-checkout-issue")
        booking.client_report_issue()
        return Response(BookingSerializer(booking).data, status=status.HTTP_200_OK)
