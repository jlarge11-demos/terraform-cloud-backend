variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}

provider "aws" {
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  region     = "us-west-1"
}

terraform {
  backend "remote" {
    organization = "jlarge11-terraform-cloud-backend"

    workspaces {
      prefix = "main-"
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
}
