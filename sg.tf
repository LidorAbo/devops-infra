resource "aws_security_group" "allow_http" {
  name        = "http_access"
  description = "Allow HTTP from my public IP"
  vpc_id      = module.vpc.id

  ingress {
    description = "HTTP access from my IP"
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = "tcp"
    cidr_blocks = [local.my_public_ipv4]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}