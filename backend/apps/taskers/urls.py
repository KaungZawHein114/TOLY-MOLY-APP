from django.urls import path

from apps.taskers.views import SkillDetailView, SkillListCreateView

urlpatterns = [
    path("skills", SkillListCreateView.as_view(), name="tasker-skills"),
    path("skills/<int:pk>", SkillDetailView.as_view(), name="tasker-skill-detail"),
]
