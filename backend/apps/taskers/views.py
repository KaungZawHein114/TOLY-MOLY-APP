from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.taskers.models import Skill
from apps.taskers.permissions import IsTasker
from apps.taskers.serializers import SkillSerializer


class SkillListCreateView(APIView):
    permission_classes = [IsTasker]

    def get(self, request):
        skills = Skill.objects.filter(tasker=request.user)
        return Response(SkillSerializer(skills, many=True).data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = SkillSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(tasker=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class SkillDetailView(APIView):
    permission_classes = [IsTasker]

    def _get_owned_skill(self, request, pk):
        return Skill.objects.filter(pk=pk, tasker=request.user).first()

    def put(self, request, pk):
        skill = self._get_owned_skill(request, pk)
        if not skill:
            return Response({"detail": "Skill not found.", "code": "skill_not_found"}, status=status.HTTP_404_NOT_FOUND)
        serializer = SkillSerializer(skill, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)

    def delete(self, request, pk):
        skill = self._get_owned_skill(request, pk)
        if not skill:
            return Response({"detail": "Skill not found.", "code": "skill_not_found"}, status=status.HTTP_404_NOT_FOUND)
        skill.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
