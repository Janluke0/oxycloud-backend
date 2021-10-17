terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.22.0"
    }
  }
}

module "website" {
  source = "./website"

  s3_origin_id  = "s3OriginId" #not clear
  bucket_prefix = "oxy-website-"
}

locals {
  ##to avoid collitions if we want to deploy multiple with a single aws account
  user_pool_domain = "oxy-user-pool-${random_string.id.result}"
  website          = "https://${module.website.domain_name}/"
}

module "authorization" {
  source = "./authorization"

  region           = var.region
  website          = local.website
  user_pool_domain = local.user_pool_domain
}

module "storage" {
  source = "./storage"

  region           = var.region
  user_pool_domain = local.user_pool_domain
}

provider "aws" {
  region = var.region
}

resource "aws_iam_role_policy_attachment" "authenticated" {
  role       = module.authorization.authenticated_role_name
  policy_arn = module.storage.user_access_policy.arn
}

resource "random_string" "id" {
  length  = 6
  special = false
  upper = false
}
