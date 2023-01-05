import csv
from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from django.urls import reverse
from django.shortcuts import redirect


from .tasks import ping_hosts

from ping_project.celery import app

from .models import Task, Host, HostStatus
from .forms import ServersForm

# Global Vars
REVOKE = 4

# Helper functions

def celery_run_task(task):
    celery_task = ping_hosts.delay(task.pk)

    task.celery_task_id = celery_task.id
    task.save()

def db_create_task_objects(hosts, task):

    for host in hosts:
        host_obj, created = Host.objects.get_or_create(hostname=host)
        host_status_obj = HostStatus.objects.create(host=host_obj)
        task.hosts.add(host_status_obj)

def celery_set_task_state(task, state):
    app.control.revoke(task.celery_task_id, terminate=True, signal='SIGKILL')

    task.status = state
    task.save()

def db_clone_task(task_id):
    old_task = Task.objects.get(id=task_id)
    new_task = Task.objects.create()

    servers = old_task.hosts.all().values_list('host__hostname', flat=True)

    db_create_task_objects(servers, new_task)

    return new_task
    
def create_hosts_json(task):

    servers = task.hosts.all().values_list('host__hostname')

    json_servers = {}

    for server in servers:
        json_servers[server[0]] = 'UKN'

    return json_servers

# Views (Controllers) from here 

def index(request):

    form = ServersForm()

    return render(request, 'index.html', {'form': form})

def ping_task_create(request):

    if request.method == 'POST':

        task = Task.objects.create()

        form = ServersForm(request.POST)

        if form.is_valid():
            db_create_task_objects(form.cleaned_data['ping_hosts'], task)

            celery_run_task(task)

            url = reverse('ping_task_run', args=[task.id])

            return redirect(url, {'task_id': task.id})
        else:

            return render(request, 'index.html', {'form': form})

    form = ServersForm()

    return render(request, 'index.html', {'form': form})


def ping_task_run(request, task_id):

    task = Task.objects.get(id=task_id)

    context = {
       'task_id': task_id,
       'task': task
    }

    return render(request, 'ping.html', context=context)


def revoke_task(request, task_id):

    task = Task.objects.get(id=task_id)

    celery_set_task_state(task, REVOKE)

    url = reverse('ping_task_run', args=[task.id])

    return redirect(url, {'task_id': task.id})


def task_relaunch(request, task_id):

    task = db_clone_task(task_id)

    celery_run_task(task)

    url = reverse('ping_task_run', args=[task.id])

    return redirect(url, {'task_id': task.id})


def tasks_list(request):

    tasks = Task.objects.all()[:10]

    return render(request, 'tasks.html', {'tasks': tasks})


def ping_task_results(request, task_id):

    task = Task.objects.get(id=task_id)

    if task.get_state_display() in ['done', 'revoked']:

        return render(request, 'ping_results.html', {'task': task})
    
    return redirect(reverse('index'))

def task_json(request, task_id):
    task = Task.objects.get(id=task_id)

    hosts = create_hosts_json(task)

    return JsonResponse({'hosts': hosts})