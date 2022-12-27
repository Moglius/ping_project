from django.shortcuts import render

from .tasks import ping2_hosts

from ping_project.celery import app

from .models import Task


# Create your views here.
def index(request):

    obj = Task.objects.create()

    celery_task = ping2_hosts.delay(obj.pk)

    obj.celery_task_id = celery_task.id
    obj.save()

    context = {
        'task_id': obj.id
    }

    return render(request, 'index.html', context=context)

# Create your views here.
def revoke_task(request, task_id):

    obj = Task.objects.get(
        id=task_id
    )

    app.control.revoke(obj.celery_task_id, terminate=True, signal='SIGKILL')

    obj.status = 4
    obj.save()

    return render(request, 'index.html')

# Create your views here.
def tasks_list(request):

    tasks = Task.objects.all()[:10]

    context = {
        'tasks': tasks
    }

    return render(request, 'tasks.html', context)