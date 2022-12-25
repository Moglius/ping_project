import os

from asgiref.sync import AsyncToSync
from celery import shared_task
from concurrent.futures import ThreadPoolExecutor, wait

from channels.layers import get_channel_layer
import asyncio

channel_layer = get_channel_layer()
executor = ThreadPoolExecutor(max_workers=50)

@shared_task
def ping_hosts():
    
    def perform_ping(host):
        response = os.system("ping -c 1 -w 1 " + host + " >/dev/null")

        if response == 0:
            status = 'UP'
        else:
            status = 'DOWN'

        return (host, status)

    hosts = {}
    futures = []

    for i in range(1,255):

        host = "192.168.0." + str(i)

        futures.append(executor.submit(perform_ping, host))
 
    completed, pending = wait(futures)

    for task in completed:
        result = task.result()
        hosts[result[0]] = result[1]

    loop = asyncio.get_event_loop()
    loop.run_until_complete(
        channel_layer.group_send(
            'ping',
            {"type": "send_new_data",
            "text": hosts
            })
    )


@shared_task
def ping2_hosts():
    
    def perform_ping(host):
        response = os.system("ping -c 1 -w 1 " + host + " >/dev/null")

        if response == 0:
            status = 'UP'
        else:
            status = 'DOWN'

        return (host, status)

    for i in range(100):
        hosts = {}
        futures = []

        for i in range(1,255):

            host = "192.168.0." + str(i)

            futures.append(executor.submit(perform_ping, host))
    
        completed, pending = wait(futures)

        for task in completed:
            result = task.result()
            hosts[result[0]] = result[1]

        loop = asyncio.get_event_loop()
        loop.run_until_complete(
            channel_layer.group_send(
                'ping2',
                {"type": "send_new_data",
                "text": hosts
                })
        )


@shared_task
def ping3_hosts():
    print('hole')