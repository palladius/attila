variable "project_id" {
  type        = string
  description = "The GCP Project ID where resources will be created."
}

variable "region" {
  type        = string
  default     = "europe-west1"
  description = "The region for the GCS buckets and other regional resources."
}

variable "gcp_identity" {
  type        = string
  description = "The GCP user identity (email) allowed to impersonate the Service Account."
}
