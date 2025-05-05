terraform {
  backend "local" {
    path = "terraform.tfstate" # State file will be stored locally in the current directory
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95.0" # Adjust the version as needed
    }
  }

  required_version = ">= 1.11.0" # Adjust based on your Terraform version
}