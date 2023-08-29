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
    bucket  = "terraform-bucket-gcpbroker-to-cloud-function"
    prefix  = "terraform/state"
  }
}


###################
##    PUB/SUB    ##
###################

resource "google_pubsub_topic" "my_topic" {
  name = "my_topic"
}

resource "google_pubsub_subscription" "my_first_subscription" {
  name   = "my_first_subscription"
  topic  = google_pubsub_topic.my_topic.id
}