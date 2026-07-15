from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve


def home(request):
    return JsonResponse({
        "status": "success",
        "message": "BitByte HRMS backend is running",
        "api": "/api/",
        "admin": "/admin/",
    })


urlpatterns = [
    path("", home, name="home"),
    path("admin/", admin.site.urls),
    path("api/", include("hrms.urls")),
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