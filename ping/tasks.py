import os, asyncio, time

from celery import shared_task
from concurrent.futures import ThreadPoolExecutor, wait

from channels.layers import get_channel_layer

from .models import Task


ITERATION_MAX = 10
ITERATION_DELAY = 3

channel_layer = get_channel_layer()
executor = ThreadPoolExecutor(max_workers=50)


def perform_ping(host):
        response = os.system("ping -c 1 -w 1 " + host + " >/dev/null")

        return (host, 'DOWN' if response else 'UP')


def run_multiprocess_tasks(hosts, task):
    futures = []

    for host_status in task.hosts.all():

        futures.append(executor.submit(
            perform_ping, host_status.host.hostname
        ))

    completed, pending = wait(futures)

    for task in completed:
        result = task.result()
        hosts[result[0]] = result[1]


def save_current_state(task, hosts):
    for hs in task.hosts.all():
        hname = hs.host.hostname
        hs.status += '1' if (hosts[hname] == 'UP') else '0'
        hs.save()

def send_channel_group_data(return_data, task_id, delay):
        
    loop = asyncio.get_event_loop()
    loop.run_until_complete(
        channel_layer.group_send(
            f"ping_{task_id}",
            {"type": "send_new_data",
            "text": return_data
            })
    )
    time.sleep(delay)

def update_task_state(task):
    task.status = 3
    task.save()


@shared_task
def ping_hosts(task_id):
    
    task, created = Task.objects.update_or_create(
        id=task_id,
        defaults={'status': 2}
    )

    for i in range(ITERATION_MAX-1):
        hosts = {}
        
        run_multiprocess_tasks(hosts, task)

        save_current_state(task, hosts)

        return_data = {
            'cur_iteration': i+1,
            'end_iteration': ITERATION_MAX,
            'hosts': hosts
        }

        send_channel_group_data(return_data, str(task_id), ITERATION_DELAY)   

    update_task_state(task)    

    return_data = {
        'cur_iteration': ITERATION_MAX,
        'end_iteration': ITERATION_MAX,
        'hosts': hosts
    }   
    
    send_channel_group_data(return_data, str(task_id), 0)
