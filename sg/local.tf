locals {
  http_port = 80
  my_public_ipv4         = "${chomp(data.http.myip.response_body)}/32"
}