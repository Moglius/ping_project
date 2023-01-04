import json

from channels.generic.websocket import AsyncWebsocketConsumer
from channels.layers import get_channel_layer

channel_layer = get_channel_layer()


class PingConsumer(AsyncWebsocketConsumer):
    
    async def connect(self):

        task_id = self.scope['url_route']['kwargs']['task_id']

        await self.channel_layer.group_add(f"ping_{task_id}", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):

        task_id = self.scope['url_route']['kwargs']['task_id']
        await self.channel_layer.group_discard(f"ping_{task_id}", self.channel_name)

    
    async def send_new_data(self, event):
        hosts = event['text']
        await self.send(json.dumps(hosts, sort_keys=True))
