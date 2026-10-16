locals {
  datasets = {
    raw     = "velib_raw"
    staging = "velib_staging"
    marts   = "velib_marts"
  }
}

# --- APIs -------------------------------------------------------------------

resource "google_project_service" "apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# --- Cloud Storage ----------------------------------------------------------

resource "google_storage_bucket" "raw" {
  name                        = var.raw_bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age            = var.raw_retention_days
      matches_prefix = ["raw/"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.apis]
}

import {
  to = google_storage_bucket.raw
  id = "${var.project_id}/${var.raw_bucket_name}"
}

# --- BigQuery ---------------------------------------------------------------

resource "google_bigquery_dataset" "this" {
  for_each = local.datasets

  dataset_id = each.value
  location   = var.location

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.apis]
}

import {
  for_each = local.datasets
  to       = google_bigquery_dataset.this[each.key]
  id       = "projects/${var.project_id}/datasets/${each.value}"
}

# --- Compte de service et droits -------------------------------------------

resource "google_service_account" "pipeline" {
  account_id   = var.service_account_id
  display_name = "Velib ELT pipeline"

  depends_on = [google_project_service.apis]
}

import {
  to = google_service_account.pipeline
  id = "projects/${var.project_id}/serviceAccounts/${var.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "pipeline_objects" {
  bucket = google_storage_bucket.raw.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_project_iam_member" "pipeline_bigquery" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.pipeline.email}"
}
