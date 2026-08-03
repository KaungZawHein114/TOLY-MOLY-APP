from django.urls import path

from apps.matching.views import ClassifyCategoryView

urlpatterns = [
    path("classify-category", ClassifyCategoryView.as_view(), name="matching-classify-category"),
]
