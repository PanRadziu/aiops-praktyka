terraform {
  required_version = ">= 1.16"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }

  # Stan lokalny w katalogu tf/ (tf/terraform.tfstate, w .gitignore).
  backend "local" {
    path = "terraform.tfstate"
  }
}
