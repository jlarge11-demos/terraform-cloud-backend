variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

locals {
  site_name = "www.dailywombat.com"

  tags = {
    site = "dailywombat"
  }
}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  region     = "us-west-1"
}

terraform {
  backend "remote" {
    organization = "dailywombat"
    
    workspaces {
      prefix = "site-"
    }
  }
}

resource "aws_dynamodb_table" "funtimes" {
  name           = "funtimes"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "alpha"

  attribute {
    name = "alpha"
    type = "S"
  }

  tags = local.tags
}
