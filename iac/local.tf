locals {
  code_directory = "../src/"
  code_zip_path  = "zip/code.zip"
  function_name  = "receive_pubsub_event"
  api_services = [
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "eventarc.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}