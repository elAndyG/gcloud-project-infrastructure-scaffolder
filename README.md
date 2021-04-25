# gcloud-project-infrastructure-scaffolder

Imagine that you are preparing your personal Google Cloud Platform project and have selected numerous PaaS APIs for your solution.

- How can your teammates match their personal GCP project so they can troubleshoot and contribute to the codebase?
- How does your DevOps engineers deploy to Development, Staging and Production without knowing the exact settings of your project?

This solution will provide a safe and repeatable process in which any GCP project's infrastructure will be configured the same way every single time.

### What makes this different?

Theres solutions out there that will prepare containers, clusters, kubes and more, but there isnt much in terms of preparing projects that focus on PaaS-only solutions.

For example, I would like to use AppEngine, PubSub, Cloud Scheduler and prepare some Cloud Tasks and Buckets. Not all solutions can manage this.

### What do you mean by "safe and repeatable"

**Safe** - All methods are idempotent. Meaning, if something exists or is already enabled, the script will skip that step and move on. This allows you to incrementally update your project as you find the need for more services. For example, your solution is already deployed to the wild. My next feature is to add 2 new Cloud Tasks. You can safely re-run the script with your changes and only those new Cloud Tasks methods will run.

**Repeatable** - Run it again, and again, and again. Same result! Run it on a different project. Same result!

## Usage

1. Copy the `__gcloud_infrastructure_helpers.sh` to your solution.
1. A driver file, such as the `sample-script.sh` should be created. (Use the sample-script to assist you.)
1. Run the script by providing a project flag. `bash sample-script.sh --project my-project`

## Flags

You can provide flags to reuse your script with different projects.

- --project - the GCP project you are targeting **(mandatory)**
- --quiet - will not prompt you for user input **(optional)**

## Enabling Services

Enable individual services by using the commands below.

```bash
# AppEngine (appengine.googleapis.com)
enable_appengine

# Datastore (datastore.googleapis.com)
enable_datastore

# Cloud Functions API (cloudfunctions.googleapis.com)
enable_cloud_functions

# Cloud Tasks (cloudtasks.googleapis.com)
enable_cloud_tasks

# Cloud Secret Manager (secretmanager.googleapis.com)
enable_secret_manager

# Cloud Resource Manager (cloudresourcemanager.googleapis.com)
enable_cloud_resource_manager

# Identity and Access Management (IAM) API (iam.googleapis.com)
enable_IAM
```

### Other services

You can enable all other services not developed above with by specifying the api as follows:

```bash
enable_gcp_service "myService.googleapis.com"
```

> Developer Notes: If there are services that seem to come up often, feel free to update the utils file and this document.

## Secrets

With Secrets Manager, you can create a Secret Placeholder that you or your DevOps team may update at a later date. Once created, there will be no version or value added to it so be sure to warn the user or update a wiki entry to fill in the value.

```bash
create_secret_placeholder "this-is-my-secret-name"
```

## Cloud Task Queue

You can create a Task Queue in App Engine. (Logging will automatically be enabled.) If the task is already created, this step will be skipped.

```bash
create_cloud_task "my-task-queue-name"
```

## Buckets

Create a GCP Bucket by supplying the name with the function. If a bucket with that name already exists, this step will automatically be skipped.

```bash
configure_bucket "my-bucket-name"
```

### Bucket lifecycle

In the event you need to configure the lifecycle of the objects in a bucket, you can do so by providing a configuration json file. See https://cloud.google.com/storage/docs/managing-lifecycles#configexamples.

```bash
configure_bucket_lifecycle "my-bucket-name" "./my-bucket-name-lifecycle.config.json"
```

### Adding a role to service account and bucket

There will be times where you may need to add permissions to a service account so that it can either read or write to a bucket.

**ELEVATED PERMISSIONS MAY BE NEEDED**  
**NOT 100% IDEMPOTENT**

```bash
add_role_to_account_and_bucket my-project "some-account@my-project.gserviceaccount.com" "roles/storage.objectCreator"
```

`*` we are marking this as not 100% idempotent because we do not look to see if the role exists. Google does, in fact, safely error out if the permission exists. So you are still safe to rerun this multiple times.

## Security, Roles, IAM

### Verify a role exists on a service account

The service account will sometimes need additional roles. Verify the role exists. The script will automatically fail and warn the user that the role is needed on the account to continue.

```bash
verify_role_to_serviceAccount my-project "some-account@my-project.gserviceaccount.com" "roles/iam.serviceAccountTokenCreator"
```

Typically you will want to check that a role exists on the default service account. Be default, you will have the variable $DEFAULT_SERVICE_ACCOUNT available for you to use. The above script will now translate to

```bash
verify_role_to_serviceAccount my-project "$DEFAULT_SERVICE_ACCOUNT" "roles/iam.serviceAccountTokenCreator"
```

## Erroring Out

During your session, you may want to fail the entire script. You can also provide a warning message if needed.

```bash
# Error the script with no message
error_exit
# Error the script with a message
error_exit "you have done something bad"
```

## Available Global Varialbes

These variables are automatically set on startup and available for you to use in your script.

- `$DEFAULT_SERVICE_ACCOUNT` - the app engine default service account for the project. Use this for validating roles or adding/changing permissions.
- `$DEFAULT_SERVICE_ACCOUNT_EXISTS` - whether or not the default service account is available for use. You will receive a warning if one does not exist (although this is unlikely)
- `$quiet` - if the user has requested to run quietly, provide functionality to use a default value or functionality.
- `$project` - The project the script is currently running under.
