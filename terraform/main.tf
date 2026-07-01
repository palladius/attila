terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# 1. Service Account Setup
resource "google_service_account" "sre_investigator" {
  account_id   = "safe-sre-investigator"
  display_name = "Safe SRE Investigator Service Account"
  description  = "Restricted Service Account used by spapparo agent for read-only SRE investigations."
}

# Key creation disabled due to org policy. Using impersonation instead.

locals {
  sre_roles = [
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/browser",
    "roles/container.viewer",
    "roles/compute.viewer",
    "roles/storage.objectViewer",
    "roles/run.viewer",
    "roles/monitoring.dashboardEditor",
    "roles/bigquery.user",
    "roles/bigquery.dataViewer",
    "roles/aiplatform.user"
  ]
}

# Grant required roles to the Service Account on the project
resource "google_project_iam_member" "sre_investigator_roles" {
  for_each = toset(local.sre_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.sre_investigator.email}"
}

# 2. GCS Buckets Setup
# Public bucket for sharing reports (non-sensitive)
resource "google_storage_bucket" "public_bucket" {
  name          = "${var.project_id}-attila-public"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Private bucket for internal memory and playbooks
resource "google_storage_bucket" "private_bucket" {
  name          = "${var.project_id}-attila-private"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
}

# Grant the Service Account access to the private bucket
resource "google_storage_bucket_iam_member" "private_bucket_sa_access" {
  bucket = google_storage_bucket.private_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.sre_investigator.email}"
}

# 3. IAM Binding for Service Account Impersonation
resource "google_service_account_iam_member" "sre_investigator_impersonator" {
  service_account_id = google_service_account.sre_investigator.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.gcp_identity}"
}

# 4. Pub/Sub Topic for approval flows and event-driven triggers
resource "google_pubsub_topic" "attila_topic" {
  name = "attila-investigations"
}
