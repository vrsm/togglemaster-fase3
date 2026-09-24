terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket = "togglemaster-fase3-tfstate-523694734848"
    key    = "togglemaster/terraform.tfstate"
    region = "us-east-1"
  }
}
