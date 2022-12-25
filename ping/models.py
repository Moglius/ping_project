from django.db import models

# Create your models here.
class Task(models.Model):
    task_id = models.CharField(max_length=255)

    def __str__(self):
        return self.task_id