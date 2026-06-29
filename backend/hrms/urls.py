from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('create-user/', views.create_user_view, name='create_user'),
    path('register-employee/', views.register_employee_view, name='register_employee'),
    path('registered-employees/', views.get_registered_employees_view, name='registered_employees'),
    path('registered-employees/<int:pk>/', views.update_employee_status_view, name='update_employee_status'),
    path('verify-employee/<int:pk>/', views.verify_employee_view, name='verify_employee'),
    path('reject-employee/<int:pk>/', views.reject_employee_view, name='reject_employee'),
    path('add-employee/<int:pk>/', views.add_employee_view, name='add_employee'),
    path('change-password/', views.change_password_view, name='change_password'),
]