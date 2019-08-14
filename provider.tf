provider "aws" {
  region = "us-west-2"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

provider "http" {
  version = "~> 1.0"
}

variable "cluster-name" {
  default = "terraform-eks"
  type    = "string"
}