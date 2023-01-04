from django.urls import path

from .consumers import PingConsumer

ws_urlpatterns = [
    path('ws/<str:task_id>/ping/', PingConsumer.as_asgi())
]