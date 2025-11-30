terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "tf-state-uday-ap-south-1"
    key    = "prometheus-setup/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
