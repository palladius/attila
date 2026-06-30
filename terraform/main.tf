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

# Generate a private key for the Service Account
resource "google_service_account_key" "sre_investigator_key" {
  service_account_id = google_service_account.sre_investigator.name
}

# Grant Viewer role to the Service Account on the project
resource "google_project_iam_member" "sre_investigator_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.sre_investigator.email}"
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

# Make the public bucket readable by anyone (as specified in the specs for sharing HTML reports)
resource "google_storage_bucket_iam_member" "public_bucket_all_users" {
  bucket = google_storage_bucket.public_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
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

# 3. Restricted Gemini API Key
resource "google_apikeys_key" "gemini_key" {
  provider     = google-beta
  name         = "attila-gemini-key"
  display_name = "A.TT.I.L.A. Gemini API Key"

  restrictions {
    api_targets {
      service = "generativelanguage.googleapis.com"
    }
  }
}

# 4. Pub/Sub Topic for approval flows and event-driven triggers
resource "google_pubsub_topic" "attila_topic" {
  name = "attila-investigations"
}
