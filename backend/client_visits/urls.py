from django.urls import path
from . import views


urlpatterns = [
    path('', views.visit_list_create, name='client_visit_list_create'),
    path('<int:pk>/', views.visit_detail, name='client_visit_detail'),
    path('<int:pk>/approval/', views.visit_approval, name='client_visit_approval'),
    path('<int:pk>/check-in/', views.visit_check_in, name='client_visit_check_in'),
    path('<int:pk>/complete/', views.visit_complete, name='client_visit_complete'),
    path('<int:pk>/attachments/', views.visit_attachment, name='client_visit_attachment'),
    path('<int:pk>/expenses/', views.visit_expense, name='client_visit_expense'),
]
