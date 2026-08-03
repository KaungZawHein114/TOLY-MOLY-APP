from rest_framework import serializers


class ClassifyCategorySerializer(serializers.Serializer):
    """The AI Tasker Finder request: one free-text problem description.

    Single-shot on purpose — this agent has no conversation and therefore no
    history, so there is nothing a caller could use to inject extra messages
    into the OpenAI call. `max_length` bounds the prompt cost.
    """

    message = serializers.CharField(
        allow_blank=False,
        trim_whitespace=True,
        max_length=1000,
    )
