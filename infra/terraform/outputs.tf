output "raw_bucket" {
  description = "Bucket des fichiers bruts"
  value       = google_storage_bucket.raw.name
}

output "datasets" {
  description = "Datasets BigQuery gérés par Terraform"
  value       = { for k, d in google_bigquery_dataset.this : k => d.dataset_id }
}

output "pipeline_service_account" {
  description = "Compte de service du pipeline"
  value       = google_service_account.pipeline.email
}
