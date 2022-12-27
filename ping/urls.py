from django.urls import path

from .views import index, revoke_task, tasks_list

urlpatterns = [
    path('', index),
    path('task/<int:task_id>/revoke/', revoke_task),
    path('tasks/', tasks_list)
]
