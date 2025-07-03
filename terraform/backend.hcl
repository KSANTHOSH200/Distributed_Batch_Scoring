terraform {
  backend "s3" {
    bucket         = "batch-scorer-tfstate"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "batch-scorer-lock"
  }
}