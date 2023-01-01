from django.db import models


class Host(models.Model):

    hostname = models.CharField(max_length=255)

    def __str__(self):
        return self.hostname
    
    class Meta:
        ordering = ('-id',)

class HostStatus(models.Model):
    
    host = models.ForeignKey(Host, on_delete=models.CASCADE)
    status = models.CharField(max_length=255, default="")

    def results(self):

        status_str, len_status = self.status, len(self.status)
        left, rigth, count, grand_total = 0,0,0,0
        cur_status = ''

        output_arr = []

        while rigth < len_status:
            if left == rigth:
                if status_str[rigth] == '1':
                    cur_status = 'UP'
                else:
                    cur_status = 'DOWN'
                count += 1
                rigth += 1
            elif status_str[rigth] == status_str[left]:
                count += 1
                rigth += 1
            elif status_str[rigth] != status_str[left]:
                percentage = (count * 100) // len_status
                grand_total += percentage
                left = rigth
                output_arr.append((percentage,cur_status))
                count = 0
        
        output_arr.append((100 - grand_total,cur_status))

        print(output_arr)

        return output_arr

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
    hosts = models.ManyToManyField(HostStatus)

    def __str__(self):
        return self.celery_task_id
    
    class Meta:
        ordering = ('-id',)

    def get_state_display(self):
        return self.states[self.status - 1][1]
