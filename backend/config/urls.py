from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("apps.authentication.urls")),
    path("api/profile/", include("apps.profiles.urls")),
    path("api/verification/", include("apps.verification.urls")),
    path("api/tasker/", include("apps.taskers.urls")),
    path("api/tasks/", include("apps.tasks.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
