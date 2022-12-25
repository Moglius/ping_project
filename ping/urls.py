from django.urls import path

from .views import index, revoke_task

urlpatterns = [
    path('', index),
    path('task/<int:job_id>/revoke/', revoke_task),
]
