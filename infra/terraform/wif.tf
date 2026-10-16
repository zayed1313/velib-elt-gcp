# Authentification GitHub Actions -> GCP sans clé (Workload Identity Federation)
# Le compte de service créé ici est en LECTURE SEULE : il ne sert qu'à lancer `terraform plan` dans la CI.

variable "github_repository" {
  description = "Dépôt GitHub autorisé à s'authentifier (format proprietaire/nom)"
  type        = string
  default     = "zayed1313/velib-elt-gcp"
}

locals {
  tfstate_bucket = "${var.project_id}-tfstate"
}

resource "google_project_service" "wif_apis" {
  for_each = toset([
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.wif_apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Seul ce dépôt peut obtenir une identité Google
  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "terraform_plan" {
  account_id   = "terraform-plan"
  display_name = "Terraform plan (CI, lecture seule)"

  depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "terraform_plan_readonly" {
  for_each = toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/iam.workloadIdentityPoolViewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_plan.email}"
}

resource "google_storage_bucket_iam_member" "terraform_plan_state" {
  bucket = local.tfstate_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.terraform_plan.email}"
}

resource "google_service_account_iam_member" "github_impersonation" {
  service_account_id = google_service_account.terraform_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

output "workload_identity_provider" {
  description = "Valeur à mettre dans la variable GitHub WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "terraform_plan_service_account" {
  description = "Compte de service utilisé par la CI"
  value       = google_service_account.terraform_plan.email
}
