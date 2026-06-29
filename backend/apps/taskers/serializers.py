from rest_framework import serializers

from apps.taskers.models import Skill


class SkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = Skill
        fields = ["id", "skill_name", "experience_years"]
