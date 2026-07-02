from django.db import models

from apps.users.models import User


class ClientProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="client_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()
    profile_picture = models.ImageField(upload_to="profile_pictures/", blank=True, null=True)

    def __str__(self):
        return self.name


class TaskerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="tasker_profile")
    name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10)
    age = models.PositiveSmallIntegerField()
    profile_picture = models.ImageField(upload_to="profile_pictures/", blank=True, null=True)
    tier = models.PositiveSmallIntegerField(default=1)
    trust_score = models.PositiveIntegerField(default=0)

    def __str__(self):
        return self.name
