from django.db import models

# Create your models here.
class Task(models.Model):

    states = (
        (1, "created"),
        (2, "running"),
        (3, "done"),
        (4, "revoked"),
    )

    celery_task_id = models.CharField(max_length=255, blank=True, null=True)
    status = models.IntegerField(choices=states, default=1)

    def __str__(self):
        return self.celery_task_id
    
    class Meta:
        ordering = ('-id',)

    def get_state_display(self):
        return self.states[self.status - 1][1]