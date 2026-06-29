from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('create-user/', views.create_user_view, name='create_user'),
    path('ceo/dashboard/', views.ceo_dashboard_view, name='ceo_dashboard'),
    path('superadmin/dashboard/', views.superadmin_dashboard_view, name='superadmin_dashboard'),
    path('hr/dashboard/', views.hr_dashboard_view, name='hr_dashboard'),
    path('tl/dashboard/', views.tl_dashboard_view, name='tl_dashboard'),
    path('tl/meetings/', views.tl_meetings_view, name='tl_meetings'),
    path('md/dashboard/', views.md_dashboard_view, name='md_dashboard'),
    path('md/meetings/', views.md_meetings_view, name='md_meetings'),
]
