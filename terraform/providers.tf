provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Project = var.project_name
        Env     = var.environment
      }
    )
  }
}

data "aws_caller_identity" "current" {}
