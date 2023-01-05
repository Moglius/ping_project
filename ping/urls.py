from django.urls import path

from .views import (
    index,
    revoke_task,
    tasks_list,
    ping_task_run,
    ping_task_create,
    ping_task_results,
    task_json,
    task_relaunch
)

urlpatterns = [
    path('', index, name='index'),
    path('task/ping/', ping_task_create, name='ping_task_create'),
    path('task/ping/<int:task_id>/', ping_task_run, name='ping_task_run'),
    path('task/ping/<int:task_id>/results/', ping_task_results, name='ping_task_results'),
    path('task/<int:task_id>/revoke/', revoke_task, name='revoke_task'),
    path('task/<int:task_id>/relaunch/', task_relaunch, name='task_relaunch'),
    path('task/<int:task_id>/json/', task_json, name='task_json'),
    path('tasks/', tasks_list, name='tasks_list'),
]
