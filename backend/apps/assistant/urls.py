from django.urls import path

from apps.assistant.views import AssistantChatView

urlpatterns = [
    path("chat", AssistantChatView.as_view(), name="assistant-chat"),
]
