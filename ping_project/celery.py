import os

from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ping_project.settings')

app = Celery('ping_project')

app.config_from_object('django.conf:settings', namespace='CELERY')

app.conf.beat_schedule = {
    'ping_host_15s': {
        'task': 'ping.tasks.ping_hosts',
        'schedule': 15.0
    }
}

app.autodiscover_tasks()