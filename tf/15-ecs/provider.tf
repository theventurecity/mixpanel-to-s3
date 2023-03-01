terraform {
  required_providers {
    aws = {
      version = "~> 4.5"
    }
  }
  backend "s3" {}
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids[var.account_type]}:role/${local.basename}-deployer"
  }
}