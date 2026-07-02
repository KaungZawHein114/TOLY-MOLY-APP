from django.db import models

from apps.users.models import User


class Skill(models.Model):
    tasker = models.ForeignKey(User, on_delete=models.CASCADE, related_name="skills")
    skill_name = models.CharField(max_length=100)
    experience_years = models.PositiveSmallIntegerField()

    def __str__(self):
        return f"{self.skill_name} ({self.experience_years}y) — {self.tasker.phone_number}"
