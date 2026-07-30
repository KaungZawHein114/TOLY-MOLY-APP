from rest_framework import serializers


class ChatTurnSerializer(serializers.Serializer):
    """One prior turn. `role` is deliberately restricted to user/assistant —
    never accept "system" from the client, or a crafted history entry could
    inject a second system message into the OpenAI call."""

    role = serializers.ChoiceField(choices=["user", "assistant"])
    content = serializers.CharField(allow_blank=True)


class AssistantChatSerializer(serializers.Serializer):
    message = serializers.CharField(allow_blank=False, trim_whitespace=True)
    history = ChatTurnSerializer(many=True, required=False, default=list)
