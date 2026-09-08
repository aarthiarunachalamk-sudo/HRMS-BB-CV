from django.urls import re_path

from .consumers import JourneyTrackingConsumer


websocket_urlpatterns = [
    re_path(
        r'^ws/client-journeys/(?P<journey_id>\d+)/tracking/$',
        JourneyTrackingConsumer.as_asgi(),
    ),
]
