data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.company_name}-vpc"] # Replace with your VPC name
  }
}