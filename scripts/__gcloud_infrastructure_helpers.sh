#!/bin/bash

# ****************************************************************************************
# Scaffold your GCP project with the methods below.
# Follow the steps within the README.md file.
#  https://www.github.com/elandyg

# Once this file is loaded, it will automatically check for the existence of
#   gcloud, gsutil, a default service account and that you are logged in.
#   No changes will begin until you are promted to contine.
#   This can be found in the *Startup* section below.

# The following variables will be globally availale:
#  -- $project
#  -- $DEFAULT_SERVICE_ACCOUNT
#  -- $DEFAULT_SERVICE_ACCOUNT_EXISTS
#  -- $quiet
#Ï
# ****************************************************************************************

quiet=${quiet:-false}

# Loops through the named parameters and declares them.
while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        if [ $param == "quiet" ]; then
            declare $param=true
        else
            declare $param="$2"
        fi
    fi
    shift
done

if [ -z "$project" ]; then
    echo "${BASH_SOURCE[1]}: FATAL: --project flag was not set. "
    exit 1
fi

DEFAULT_SERVICE_ACCOUNT_EXISTS=false
DEFAULT_SERVICE_ACCOUNT=$project@appspot.gserviceaccount.com

# Exit with a message and an exit code.
#   Arguments:
#     $1 - string with an error message
#     $2 - exit code, defaults to 1
function error_exit() {
    # ${BASH_SOURCE[1]} is the file name of the caller.
    echo "${BASH_SOURCE[1]}: line ${BASH_LINENO[0]}: ${1:-Unknown Error.} (exit ${2:-1})" 1>&2
    exit ${2:-1}
}

# Verify a service is enabled.
#   Arguments:
#     $1 - service to enable
function __is_service_enabled() {
    is_enabled=$(gcloud services list --enabled --filter="name:$1" --format="value(state)" --project=$project)
    if [[ $is_enabled == "ENABLED" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Validates that the GCloud and GSUtil SDKs are present and that a permitted user is logged in. Exists if not configured.
#   Arguments:
#   Usage: > validate_gcp_installation
function __validate_gcp_installation() {
    # Verify the user has gcloud installed
    echo "Verifying gcloud installation..."
    if ! gcloud --version; then
        error_exit "GCloud SDK does not exist and cannot continue."
    fi
    echo "done.\n"

    # Verify the user has gsutil installed
    echo "Verifying gsutil installation..."
    if ! gsutil --version; then
        error_exit "gsutil does not exist and cannot continue."
    fi
    echo "done.\n"

    echo "Verifying you are logged in..."
    __validate_account "$project"
    echo "done.\n"
}

# Verify an account is logged in, if not it will exit the script.
#   Usage: > __validate_account
function __validate_account() {
    ACCOUNT=$(gcloud auth list --filter="status:ACTIVE" --format="value(account)" --project=$project)
    [[ -n "${ACCOUNT}" ]] || error_exit "ERROR: You did not log in. run gcloud auth login or use a service account file."
}

# Prompt the user of which project they will be configuring.
# User can press Control + C to exit before anything runs
#   Arguments:
#     $1 - true/false - do not prompt user for verification
#   Usage: > __prompt_user_of_configuration_and_await_keydown
function __prompt_user_of_configuration_and_await_keydown() {
    echo "This script will make environment and account changes to your gcloud project environment."
    echo "Project: $project"
    echo "Account: $(gcloud auth list --filter="status:ACTIVE" --format="value(account)" --project="$project")"
    if ! $1; then
        echo "Verify the project name and account then press any key to continue, or Control + C to cancel"
        read
    else
        echo "Running quietly. Will accept all defaults."
        echo "\n"
    fi
}

# Validates that the project flag was set and that the active user has access to that project.
#   Arguments:
#   Usage: > __validate_project_exists_and_accessible
function __validate_project_exists_and_accessible() {
    echo "Validating access to the project $project."
    PROJECT_RESULT=$(gcloud projects list --filter="$project" --format="value(project_id)")
    [[ -n "${PROJECT_RESULT}" ]] || error_exit "ERROR: The project [$project] cannot be validated. Verify you have spelled it correctly or this account has permissions to access it."
    echo "done.\n"

}

# Verifies that a default service account exists on the project.
#   Usage" > __check_if_default_serviceaccount_exists
function __check_if_default_serviceaccount_exists() {
    echo "Verifying a default service account [$DEFAULT_SERVICE_ACCOUNT] exists."
    EMAIL=$(gcloud iam service-accounts describe "$DEFAULT_SERVICE_ACCOUNT" --format="value(email)" --project "$project")

    if [ -z "$EMAIL" ]; then
        echo "WARNING: No service account exists for [$DEFAULT_SERVICE_ACCOUNT]. "
    else
        echo "Default service account exists.\n"
        DEFAULT_SERVICE_ACCOUNT_EXISTS=true
    fi
}

# Startup
# *******************************************************
__validate_gcp_installation
__validate_project_exists_and_accessible
__check_if_default_serviceaccount_exists
__prompt_user_of_configuration_and_await_keydown $quiet
# *******************************************************

# Verfies a custom service account exists.
#   If service account does not exist, the script will Error out..
#   Arguments:
#     $1 - service account to verify
#   Usage: verify_service_account_exists "cloud-convert@$project.iam.gserviceaccount.com"
function verify_service_account_exists() {
    echo "Verifying a service account [$1] exists."
    EMAIL=$(gcloud iam service-accounts describe "$1" --format="value(email)" --project "$project")

    if [ -z "$EMAIL" ]; then
        error_exit "WARNING: No service account exists for [$1] has been configured. "
    else
        echo "Service account [$1] exists.\n"
    fi
}
# Enables a GCP service.
#   In the event the service is enabled, no action will be taken.
#   Arguments:
#     $1 - service to enable
function enable_gcp_service() {
    service_enabled=$(__is_service_enabled $1)
    if [[ $service_enabled == "true" ]]; then
        echo "[$1] is already enabled. No further action needed."
    else
        gcloud services enable $1 --project "$project"
    fi

}

# Enables AppEngine API
#   Usage: > enable_appengine
function enable_appengine() {
    echo "Enabling AppEngine (appengine.googleapis.com) on project [$project]."
    enable_gcp_service appengine.googleapis.com
    echo "done.\n"
}

# Enables the Datastore API (Firestore in Datastore mode)
#   Usage: > enable_datastore
function enable_datastore() {
    echo "Enabling Datastore (datastore.googleapis.com) on project [$project]."
    enable_gcp_service datastore.googleapis.com
    echo "done.\n"
}

# Enables the Cloud Functions API (Firestore in Datastore mode)
#   Usage: > enable_datastore
function enable_cloud_functions() {
    echo "Enabling Cloud Functions API (cloudfunctions.googleapis.com) on project [$project]."
    enable_gcp_service cloudfunctions.googleapis.com
    echo "done.\n"
}

# Enables the Cloud Tasks API
#   Usage: > enable_cloud_tasks
function enable_cloud_tasks() {
    echo "Enabling Cloud Tasks (cloudtasks.googleapis.com) on project [$project]."
    enable_gcp_service cloudtasks.googleapis.com
    echo "done. \n"
}

# Enables the Secret Manager API
#   Usage: > enable_secret_manager
function enable_secret_manager() {
    echo "Enabling Cloud Secret Manager (secretmanager.googleapis.com) on project [$project]."
    enable_gcp_service secretmanager.googleapis.com
    echo "done. \n"
}

# Enables the Cloud Resource Manager API
#   Usage: > enable_cloud_resource_manager
function enable_cloud_resource_manager() {
    echo "Enabling Cloud Resource Manager (cloudresourcemanager.googleapis.com) on project [$project]."
    enable_gcp_service cloudresourcemanager.googleapis.com
    echo "done. \n"
}

# Enables the IAM API
#   Usage: > enableIAM
function enable_IAM() {
    echo "Enabling Identity and Access Management (IAM) API (iam.googleapis.com) on project [$project]."
    enable_gcp_service iam.googleapis.com
    echo "done.\n"
}

# Enables the Cloud Scheduler API
#   Usage: > enable_cloud_scheduler
function enable_cloud_scheduler() {
    echo "Enabling Cloud Scheduler API (cloudscheduler.googleapis.com) on project [$project]."
    enable_gcp_service cloudscheduler.googleapis.com
    echo "done.\n"
}

# Creates a Secret placeholder in Secret Manager.
#  You will need to manually add the data. If secret exists, no action will be taken.
#  Usage: > create_secret_placeholder "this-is-my-secret-name"
function create_secret_placeholder() {
    echo "Creating secret [$1] on project [$project]."
    _secret_date=$(gcloud secrets list --filter="$1" --format="value(createTime)" --project=$project)
    if [ -z "$_secret_date" ]; then
        gcloud secrets create $1 --project $project
        echo "done. \n"
    else
        echo "Secret [$1] was created on [$_secret_date]. No action will be taken.\n"
    fi
}

# Creates a Task Queue in App Engine. Will automatically enable logging.
#   Arguments:
#       $1 - the name of your task
#   Usage: > create_cloud_task "my-task-queue-name"
function create_cloud_task() {
    echo "Creating a Task Queue [$1] on project [$project]"
    TASK_EXISTS=$(gcloud tasks queues list --filter="$1" --format="value(name)" --project=$project)

    if [ -z "$TASK_EXISTS" ]; then
        gcloud tasks queues create $1 --log-sampling-ratio=1.0 --project $project
        echo "done. \n"
    else
        echo "Tasks Queue [$1] already exists. Skipping...\n"
    fi

}

# Creates a GCP bucket. If the bucket already exists, it will be skipped.
#   Arguments:
#       $1 - the name of your bucket
#   Usage: > configure_bucket "gs://my-bucket-name"
function configure_bucket() {
    echo "Creating bucket [$1] on project [$project]."
    if gsutil ls -b -p "$project" "$1"; then
        echo "Bucket already exists.\n"
    else
        gsutil mb -p "$project" "$1"
        echo "Created.\n"
    fi
}

# Configures the lifecycle of a GCP bucket's objects.
# A json file is needed with a configuration. See - https://cloud.google.com/storage/docs/managing-lifecycles#configexamples
#   Arguments:
#       $1 - the name of your bucket
#       $2 - the configuration file for the lifecycle configuration
#   Usage: > configure_bucket_lifecycle "gs://my-bucket-name" "./bucket-lifecycle.config.json"
function configure_bucket_lifecycle() {
    if [ -z "$2" ]; then
        error_exit "ARGUMENT_EXCEPTION: bucket lifecycle config file was not provided."
    fi

    if [ -f "$2" ]; then
        echo "Configuring the lifecycle for bucket [$1] with [$2]."
        gsutil lifecycle set $2 $1
        echo "Allow 24 hours for lifecycle changes to be applied."
        echo "done.\n"
    else
        error_exit "ARGUMENT_EXCEPTION: $2 does not exist."
    fi

}

# Verify a role in a gcp account
#   Arguments:
#       $1 - the email of the account being modified
#       $2 - the role you would like to add
#   Usage" > verify_role_to_serviceAccount my-project "some-account@my-project.gserviceaccount.com" "roles/iam.serviceAccountTokenCreator"
function verify_role_on_serviceAccount() {
    echo "Validating role [$2] exists on service account [$1]..."
    ROLE_EXISTS=$(gcloud projects get-iam-policy $project --filter="bindings.members:$1 AND bindings.role=$2" --flatten="bindings[].members" --format="value(bindings.role)")

    if [ -z "$ROLE_EXISTS" ]; then
        error_exit "ACTION NEEDED: You must add the role $2 to $1."
    else
        echo "done.\n"
    fi
}

# Add a role to a service account and bucket
#   Arguments:
#       $1 - bucket name
#       $2 - the email of the service account being modified
#       $3 - the role you would like to add
#   Usage" > add_role_to_account_and_bucket gs://my-project-bucket "some-account@my-project.gserviceaccount.com" "roles/storage.objectCreator"
function add_role_to_account_and_bucket() {
    ## Cloud Convert reader permissions for the general upload bucket
    echo "Adding the role: [$3] to [$2] for bucket [$1]."
    if gsutil iam ch serviceAccount:$2:$3 $1; then
        # a gcloud message will be displayed
        echo ""
    else
        echo "ACTION NEEDED: An error trying to update this bucket. You will need to manually add or verify that Service Account: [$2] is provided [$3] role to the bucket [$1]."

    fi
    echo "done.\n"
}

# Creates a private key in this directory named key.json.
#   Arguments:
#       $1 - servive account
#   Usage" > add_role_to_account_and_bucket gs://my-project-bucket "some-account@my-project.gserviceaccount.com" "roles/storage.objectCreator"
function create_private_key_for_service_account() {

    echo "Creating private key for service account [$0]."
    gcloud iam service-accounts keys create --iam-account $0 key.json --project=$project
    echo "done.\n"
}

#  To be used in conjunction with create_private_key_for_service_account to clean up your results
function cleanup_private_key() {
    echo "Deleteing key.json"
    if ! rm key.json; then
        echo "ACTION NEEDED: key.json could not be deleted. You must manually remove it."
    fi
    echo "done.\n"
}
