###################
## CONFIGURATION ##
###################

provider "google" {
  project = "gcpbroker-to-cloud-function"
  region  = "europe-west1"
}

resource "google_storage_bucket" "terraform-bucket-for-state" {
  name                        = "terraform-bucket-gcpbroker-to-cloud-function"
  location                    = "europe-west1"
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

terraform {
  backend "gcs" {
    bucket = "terraform-bucket-gcpbroker-to-cloud-function"
    prefix = "terraform/state"
  }
}

resource "google_project_service" "enable_services" {
  for_each = toset(local.api_services)
  project  = "gcpbroker-to-cloud-function"
  service  = each.value
}


###################
##    PUB/SUB    ##
###################

resource "google_pubsub_topic" "my_topic" {
  name = "my_topic"
}

resource "google_pubsub_subscription" "my_first_subscription" {
  name  = "my_first_subscription"
  topic = google_pubsub_topic.my_topic.id
}


###################
# CLOUD FUNCTION  #
###################

# Création du bucket contenant le code de la cloud function
resource "google_storage_bucket" "bucket_pubsub_function" {
  name     = "bucket-gcpbroker-to-cloud-function"
  location = "europe-west1"
}

# Créez le fichier zip à partir du répertoire de code
data "archive_file" "function_archive" {
  type        = "zip"
  source_dir  = local.code_directory
  output_path = local.code_zip_path
}

# Add zip file on bucket for cloud function
resource "google_storage_bucket_object" "pubsub_function_source" {
  name         = format("%s#%s", local.function_name, data.archive_file.function_archive.output_md5)
  bucket       = google_storage_bucket.bucket_pubsub_function.name
  source       = local.code_zip_path
  content_type = "application/zip"
}

# Create Cloud function triggered by pubsub event
resource "google_cloudfunctions2_function" "pubsub_function" {
  name        = "my-topic-subscriber"
  location    = "europe-west1"
  description = "Pub/Sub my_topic Subscriber Function"
  build_config {
    runtime     = "python311"
    entry_point = "subscribe"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket_pubsub_function.name
        object = google_storage_bucket_object.pubsub_function_source.name
      }
    }
  }

  service_config {
    max_instance_count             = 3
    min_instance_count             = 1
    available_memory               = "256M"
    timeout_seconds                = 60
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
  }

  event_trigger {
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.my_topic.id
    retry_policy   = "RETRY_POLICY_RETRY"
    trigger_region = "europe-west1"
  }

  lifecycle {
    create_before_destroy = true
  }
}