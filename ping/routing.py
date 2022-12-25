from django.urls import path

from .consumers import PingConsumer, Ping2Consumer

ws_urlpatterns = [
    path('ws/ping/', PingConsumer.as_asgi()),
    path('ws/ping2/', Ping2Consumer.as_asgi())
]