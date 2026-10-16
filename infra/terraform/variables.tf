variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "region" {
  description = "Région par défaut du provider"
  type        = string
  default     = "europe-west1"
}

variable "location" {
  description = "Localisation du bucket et des datasets BigQuery"
  type        = string
  default     = "EU"
}

variable "raw_bucket_name" {
  description = "Nom du bucket Cloud Storage des fichiers bruts"
  type        = string
}

variable "raw_retention_days" {
  description = "Durée de conservation des fichiers raw dans Cloud Storage (jours)"
  type        = number
  default     = 30
}

variable "service_account_id" {
  description = "Identifiant du compte de service du pipeline"
  type        = string
  default     = "velib-elt"
}
