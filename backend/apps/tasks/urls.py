from django.urls import path

from apps.tasks.views import (
    AnalyzeTaskView,
    BudgetOptionsView,
    ClientConfirmCheckinView,
    ClientConfirmCheckoutView,
    ClientRejectCheckinView,
    ClientReportCheckoutIssueView,
    ExtractTaskView,
    TaskDetailView,
    TaskListCreateView,
    TranscribeAudioView,
    WorkerCheckinView,
    WorkerCheckoutView,
)

urlpatterns = [
    # ── AI helpers ────────────────────────────────────────────────────────────
    path("ai/transcribe", TranscribeAudioView.as_view(), name="task-ai-transcribe"),
    path("ai/analyze", AnalyzeTaskView.as_view(), name="task-ai-analyze"),
    path("ai/extract", ExtractTaskView.as_view(), name="task-ai-extract"),
    path("ai/budget-options", BudgetOptionsView.as_view(), name="task-ai-budget-options"),
    # ── Task CRUD ─────────────────────────────────────────────────────────────
    path("", TaskListCreateView.as_view(), name="task-list-create"),
    path("<int:pk>", TaskDetailView.as_view(), name="task-detail"),
    # ── Booking check-in / check-out lifecycle ────────────────────────────────
    path("bookings/<int:pk>/worker-checkin/", WorkerCheckinView.as_view(), name="booking-worker-checkin"),
    path("bookings/<int:pk>/client-confirm-checkin/", ClientConfirmCheckinView.as_view(), name="booking-client-confirm-checkin"),
    path("bookings/<int:pk>/client-reject-checkin/", ClientRejectCheckinView.as_view(), name="booking-client-reject-checkin"),
    path("bookings/<int:pk>/worker-checkout/", WorkerCheckoutView.as_view(), name="booking-worker-checkout"),
    path("bookings/<int:pk>/client-confirm-checkout/", ClientConfirmCheckoutView.as_view(), name="booking-client-confirm-checkout"),
    path("bookings/<int:pk>/client-report-checkout-issue/", ClientReportCheckoutIssueView.as_view(), name="booking-client-report-checkout-issue"),
]
