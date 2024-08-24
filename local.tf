locals {
  http_port = 80
  cluster_name = "${var.company_name}-eks"
  vpc_cidr               = "192.168.0.0/16"
  additional_bit_to_cidr = 8
  azs                    = ["${var.region}a", "${var.region}b"]
  public_subnets         = [for i in range(2) : cidrsubnet(local.vpc_cidr, local.additional_bit_to_cidr, i)]
  private_subnets        = [for i in range(2) : cidrsubnet(local.vpc_cidr, local.additional_bit_to_cidr, i + 2)]
  my_public_ipv4         = "${chomp(data.http.myip.response_body)}/32"
}