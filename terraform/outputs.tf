output "service_account_email" {
  value       = google_service_account.sre_investigator.email
  description = "The email of the created Service Account."
}

output "public_bucket_name" {
  value       = google_storage_bucket.public_bucket.name
  description = "The name of the public GCS bucket."
}

output "private_bucket_name" {
  value       = google_storage_bucket.private_bucket.name
  description = "The name of the private GCS bucket."
}

output "pubsub_topic_name" {
  value       = google_pubsub_topic.attila_topic.name
  description = "The name of the Pub/Sub topic."
}
