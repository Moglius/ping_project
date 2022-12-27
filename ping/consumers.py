from channels.generic.websocket import AsyncWebsocketConsumer, WebsocketConsumer
import json

from channels.layers import get_channel_layer

from .tasks import ping2_hosts

channel_layer = get_channel_layer()

class PingConsumer(AsyncWebsocketConsumer):
    
    async def connect(self):

        await self.channel_layer.group_add('ping', self.channel_name)
        await self.accept()
    
    async def disconnect(self, close_code):

        await self.channel_layer.group_discard('ping', self.channel_name)

    
    async def send_new_data(self, event):
        hosts = event['text']
        await self.send(json.dumps(hosts, sort_keys=True))

class Ping2Consumer(AsyncWebsocketConsumer):
    
    async def connect(self):

        task_id = self.scope['url_route']['kwargs']['task_id']

        await self.channel_layer.group_add(f"ping2_{str(task_id)}", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):

        task_id = self.scope['url_route']['kwargs']['task_id']
        await self.channel_layer.group_discard(f"ping2_{str(task_id)}", self.channel_name)

    
    async def send_new_data(self, event):
        hosts = event['text']
        await self.send(json.dumps(hosts, sort_keys=True))
