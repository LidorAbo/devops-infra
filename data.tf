data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}
data "http" "github_actions_ips" {
  url = "https://api.github.com/meta"
}
data "aws_caller_identity" "current" {}