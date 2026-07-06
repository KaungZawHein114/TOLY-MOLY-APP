from django.urls import path

from apps.tasks.views import (
    AnalyzeTaskView,
    BudgetOptionsView,
    ExtractTaskView,
    TaskDetailView,
    TaskListCreateView,
    TranscribeAudioView,
)

urlpatterns = [
    path("ai/transcribe", TranscribeAudioView.as_view(), name="task-ai-transcribe"),
    path("ai/analyze", AnalyzeTaskView.as_view(), name="task-ai-analyze"),
    path("ai/extract", ExtractTaskView.as_view(), name="task-ai-extract"),
    path("ai/budget-options", BudgetOptionsView.as_view(), name="task-ai-budget-options"),
    path("", TaskListCreateView.as_view(), name="task-list-create"),
    path("<int:pk>", TaskDetailView.as_view(), name="task-detail"),
]
