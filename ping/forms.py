import validators
import re

from django import forms

from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _


def is_valid_hostname(host):
    if len(host) > 255:
        return False
    if host[-1] == ".":
        host = host[:-1] # strip exactly one dot from the right, if present
    allowed = re.compile("(?!-)[A-Z\d-]{1,63}(?<!-)$", re.IGNORECASE)
    return all(allowed.match(x) for x in host.split("."))

def is_valid_ipv4(host):
    if validators.ipv4(host) is True:
        return True
    else:
        return False

def is_valid_server(host):

    return is_valid_ipv4(host) or is_valid_hostname(host)


class ServersForm(forms.Form):
    ping_hosts = forms.CharField(label='Ping Hosts',
        widget=forms.TextInput(attrs={'placeholder': 'host1,host2,ipaddress...'}))

    def clean_ping_hosts(self):
        data = self.cleaned_data['ping_hosts']

        hosts = data.split(',')

        for host in hosts:

            if is_valid_server(host) is False:
                raise ValidationError(_('Invalid hosts or IP addresses'))

        return hosts
