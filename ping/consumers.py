from channels.generic.websocket import AsyncWebsocketConsumer
import json

from channels.layers import get_channel_layer

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
