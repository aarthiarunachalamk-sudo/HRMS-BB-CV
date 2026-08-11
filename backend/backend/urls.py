from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from client_visits import views as client_visit_views
from client_visits import journey_views
from rest_framework_simplejwt.views import TokenRefreshView
import time


def home(request):
    return JsonResponse({
        "status": "success",
        "message": "BitByte HRMS backend is running",
        "api": "/api/",
        "admin": "/admin/",
    })


def health(request):
    """Lightweight health-check endpoint used by the keep-alive ping."""
    return JsonResponse({"status": "ok", "ts": int(time.time())})


urlpatterns = [
    path("", home, name="home"),
    path("api/health/", health, name="health"),
    path("admin/", admin.site.urls),
    path("api/", include("hrms.urls")),
    path("api/client-visits/", include("client_visits.urls")),
    path("api/client-journeys/", include("client_visits.journey_urls")),
    path("api/team/client-journeys/active/", journey_views.team_active_journeys),
    path("api/team/client-journeys/history/", journey_views.team_journey_history),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path(
        "track/client-visit/<str:token>/",
        client_visit_views.public_tracking_page,
        name="client_visit_public_tracking_page",
    ),
]


if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT,
    )

    urlpatterns += [
        path(
            "attendance-media/<path:path>",
            serve,
            {
                "document_root": settings.BASE_DIR / "attendance",
            },
        ),
    ]
