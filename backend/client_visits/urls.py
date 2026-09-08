from django.urls import path
from . import views


urlpatterns = [
    path('', views.visit_list_create, name='client_visit_list_create'),
    path('client-details/', views.client_service_details, name='client_service_details'),
    path('approvers/', views.visit_approvers, name='client_visit_approvers'),
    path('<int:pk>/', views.visit_detail, name='client_visit_detail'),
    path('<int:pk>/approval/', views.visit_approval, name='client_visit_approval'),
    path('<int:pk>/check-in/', views.visit_check_in, name='client_visit_check_in'),
    path('<int:pk>/start-travel/', views.visit_start_travel, name='client_visit_start_travel'),
    path('<int:pk>/reached-client/', views.visit_reached_client, name='client_visit_reached_client'),
    path('<int:pk>/location/', views.visit_location, name='client_visit_location'),
    path('<int:pk>/tracking-link/', views.visit_tracking_link, name='client_visit_tracking_link'),
    path('public-track/<str:token>/', views.public_tracking_data, name='client_visit_public_tracking_data'),
    path('<int:pk>/progress/', views.visit_progress, name='client_visit_progress'),
    path('<int:pk>/complete/', views.visit_complete, name='client_visit_complete'),
    path('<int:pk>/verify/', views.visit_verify, name='client_visit_verify'),
    path('<int:pk>/attachments/', views.visit_attachment, name='client_visit_attachment'),
    path('<int:pk>/expenses/', views.visit_expense, name='client_visit_expense'),
]
