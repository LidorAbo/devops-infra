terraform {
  backend "s3" {
    bucket         = "devops-infra-company"
    key            = "ecr/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}