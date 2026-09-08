from django.urls import path

from . import journey_views as views


urlpatterns = [
    path('', views.journey_list_create, name='client_journey_list_create'),
    path('assignees/', views.journey_assignees, name='client_journey_assignees'),
    path('<int:pk>/', views.journey_detail, name='client_journey_detail'),
    path('<int:pk>/ready/', views.journey_ready, name='client_journey_ready'),
    path('<int:pk>/start/', views.journey_start, name='client_journey_start'),
    path('<int:pk>/locations/batch/', views.journey_locations_batch, name='client_journey_locations_batch'),
    path('<int:pk>/latest-location/', views.journey_latest_location, name='client_journey_latest'),
    path('<int:pk>/route/', views.journey_route, name='client_journey_route'),
    path('<int:pk>/complete/', views.journey_complete, name='client_journey_complete'),
    path('<int:pk>/cancel/', views.journey_cancel, name='client_journey_cancel'),
]
