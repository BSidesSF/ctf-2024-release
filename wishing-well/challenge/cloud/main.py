import functions_framework
import base64
import json
import os

from google.cloud import pubsub_v1

PROJECT_ID = "bsides-sf-ctf-2023"

# Instantiates a Pub/Sub client
publisher = pubsub_v1.PublisherClient()


# Publishes a message to a Cloud Pub/Sub topic.
def publish(request):
    request_json = request.get_json(silent=True)

    topic_name = "wishing-well"
    message = "CTF{W1sh3s-publish3d-gr4nt3d}"

    print(f"Publishing message to topic {topic_name}")

    # References an existing topic
    topic_path = publisher.topic_path(PROJECT_ID, topic_name)

    message_json = json.dumps(
        {
            "data": {"message": message},
        }
    )
    message_bytes = message_json.encode("utf-8")

    # Publishes a message
    try:
        publish_future = publisher.publish(topic_path, data=message_bytes)
        publish_future.result()  # Verify the publish succeeded
        return "Message published."
    except Exception as e:
        print(e)
        return (e, 500)