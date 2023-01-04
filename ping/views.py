import csv
from django.shortcuts import render
from django.http import HttpResponse
from django.urls import reverse
from django.shortcuts import redirect


from .tasks import ping_hosts

from ping_project.celery import app

from .models import Task, Host, HostStatus

domains = (
    (1, "NA"),
    (2, "UPS"),
    (3, "EA"),
    (4, "AP"),
)

def index(request):

    context = {
        'domains': domains
    }

    return render(request, 'index.html', context=context)

def ping_task_create(request):

    if request.method == 'POST':

        task_obj = Task.objects.create()

        hosts = request.POST['ping_hosts'].split(',')

        for host in hosts:
            host_obj, created = Host.objects.get_or_create(hostname=host)
            host_status_obj = HostStatus.objects.create(host=host_obj)
            task_obj.hosts.add(host_status_obj)

        celery_task = ping_hosts.delay(task_obj.pk)

        task_obj.celery_task_id = celery_task.id
        task_obj.save()

        context = {
            'task_id': task_obj.id
        }

        url = reverse('ping_task_run', args=[task_obj.id])

        return redirect(url, context)

    return render(request, 'index.html')


def ping_task_run(request, task_id):

    task = Task.objects.get(id=task_id)

    context = {
       'task_id': task_id,
       'task': task
    }

    return render(request, 'ping.html', context=context)


def revoke_task(request, task_id):

    obj = Task.objects.get(id=task_id)

    app.control.revoke(obj.celery_task_id, terminate=True, signal='SIGKILL')

    obj.status = 4
    obj.save()

    return render(request, 'index.html')

def tasks_list(request):

    tasks = Task.objects.all()[:10]

    context = {
        'tasks': tasks
    }

    return render(request, 'tasks.html', context)


def ping_task_results(request, task_id):

    task = Task.objects.get(
        id=task_id
    )

    if task.get_state_display() in ['done', 'revoked']:

        context = {
            'task': task
        }

        return render(request, 'ping_results.html', context=context)
    
    return render(request, 'index.html')