terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Le nom du bucket est passé à l'init : terraform init -backend-config="bucket=..."
  backend "gcs" {
    prefix = "velib-elt-gcp"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
