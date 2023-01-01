from django.urls import path

from .views import (
    index,
    revoke_task,
    tasks_list,
    ping_task_run,
    ping_task_create,
    adsearch_task_create,
    export_csv,
    ping_task_results
)

urlpatterns = [
    path('', index, name='index'),
    path('task/ping/', ping_task_create, name='ping_task_create'),
    path('task/ping/<int:task_id>/', ping_task_run, name='ping_task_run'),
    path('task/ping/<int:task_id>/results/', ping_task_results, name='ping_task_results'),
    path('task/<int:task_id>/revoke/', revoke_task, name='remove_task'),
    path('tasks/', tasks_list, name='tasks_list'),
    path('task/adsearch/', adsearch_task_create, name='adsearch_task_create'),
    path('export/csv/', export_csv, name='export_csv'),
]
