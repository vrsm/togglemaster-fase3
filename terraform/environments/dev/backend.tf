terraform {
  backend "s3" {
    bucket       = "REPLACE_WITH_YOUR_TFSTATE_BUCKET"
    key          = "togglemaster/dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
