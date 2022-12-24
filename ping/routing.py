from django.urls import path

from .consumers import PingConsumer

ws_urlpatterns = [
    path('ws/ping/', PingConsumer.as_asgi())
]