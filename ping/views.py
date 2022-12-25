from django.shortcuts import render

from .tasks import ping2_hosts

from ping_project.celery import app

from .models import Task


# Create your views here.
def index(request):

    result = ping2_hosts.delay()

    obj, created = Task.objects.get_or_create(
        task_id=result.id
    )

    context = {
        'job_id': obj.id
    }

    return render(request, 'index.html', context=context)

# Create your views here.
def revoke_task(request, job_id):

    #ping2_hosts.delay()
    #app.control.revoke('f6d3935f-940e-477e-9acf-fa07b6b1f15b', terminate=True, signal='SIGKILL')
    obj = Task.objects.get(
        id=job_id
    )

    app.control.revoke(obj.task_id, terminate=True, signal='SIGKILL')

    return render(request, 'index.html')