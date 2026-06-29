from django.db import models

from apps.users.models import User


class ClientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="client_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()

    def __str__(self):
        return self.name


class TaskerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="tasker_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()

    def __str__(self):
        return self.name
