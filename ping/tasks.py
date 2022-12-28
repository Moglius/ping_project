import os

from asgiref.sync import AsyncToSync
from celery import shared_task
from concurrent.futures import ThreadPoolExecutor, wait

from channels.layers import get_channel_layer
import asyncio

from .models import Task
import time

channel_layer = get_channel_layer()
executor = ThreadPoolExecutor(max_workers=50)

ITERATION_MAX = 100


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
def ping2_hosts(task_id):
    
    def perform_ping(host):
        response = os.system("ping -c 1 -w 1 " + host + " >/dev/null")

        if response == 0:
            status = 'UP'
        else:
            status = 'DOWN'

        return (host, status)

    obj = Task.objects.get(
        id=task_id
    )

    obj.status = 2
    obj.save()

    for i in range(ITERATION_MAX):
        hosts = {}
        futures = []

        for host in obj.hosts.all():

            futures.append(executor.submit(perform_ping, host.hostname))
    
        completed, pending = wait(futures)

        for task in completed:
            result = task.result()
            hosts[result[0]] = result[1]

        return_data = {
            'cur_iteration': i,
            'end_iteration': ITERATION_MAX,
            'hosts': hosts
        }

        loop = asyncio.get_event_loop()
        loop.run_until_complete(
            channel_layer.group_send(
                f"ping2_{str(task_id)}",
                {"type": "send_new_data",
                "text": return_data
                })
        )

        time.sleep(3)
    
    obj.status = 3
    obj.save()


@shared_task
def ping3_hosts():
    print('hole')