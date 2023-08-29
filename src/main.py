# [START functions_cloudevent_pubsub]
import logging

from cloudevents.http import CloudEvent
import functions_framework


# Triggered from a message on a Cloud Pub/Sub topic.
@functions_framework.cloud_event
def subscribe(cloud_event: CloudEvent) -> None:
    # Print out the data from Pub/Sub, to prove that it worked
    print(cloud_event.data["message"])
    logging.info(cloud_event)


# [END functions_cloudevent_pubsub]