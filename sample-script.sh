#!/bin/bash

# {{Project Name}} Infrastructure Setup

#   Usage > bash sample-script.sh --project my-personal-project
#         > bash sample-script.sh --project my-personal-project --quiet  (for automation)

source ./scripts/__gcloud_infrastructure_helpers.sh

# Enable GCP Services
enable_appengine
# enable_datastore
# enable_cloud_scheduler

# ## Example of enabling an API not configured in this script
# enable_gcp_service "bigquery.googleapis.com"

# # Configuring a GCP Bucket
# configure_bucket "gs://delete-this-sample-bucket"

# # Configure the bucket's lifecycle. (You are expected to provide a config file)
# #  https://cloud.google.com/storage/docs/managing-lifecycles#configexamples
# configure_bucket_lifecycle "gs://delete-this-sample-bucket" "delete-this-sample-bucket-lifecycle.config.json"

# # Create a Cloud Task
# create_cloud_task "my-task-A"
# create_cloud_task "my-task-B"

# # Create a Secret Placeholder
# create_secret_placeholder "my-secret-no-value"
# create_secret_placeholder "my-secret-2-no-value"

# # Role Management
# verify_role_to_serviceAccount my-project "some-account@my-project.gserviceaccount.com" "roles/iam.serviceAccountTokenCreator"
# verify_role_to_serviceAccount my-project "some-account@my-project.gserviceaccount.com" "roles/cloudfunctions.invoker"

# # TODO: Add role to account
# # TODO: Create Secret With a Value
