terraform {
  backend "s3" {
    bucket = "datcyber-bucket" # Replace with your actual S3 bucket name
    key    = "datcyber/terraform.tfstate"
    region = "us-east-1"
  }
}
