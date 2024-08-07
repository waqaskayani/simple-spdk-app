module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.default_name
  cidr = var.vpc_cidr

  azs                       = ["us-west-1a", "us-west-1b"]
  public_subnets            = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway        = false
  public_route_table_tags   = {
    Name = "${var.default_name}-public-rt"
  }

  enable_dns_hostnames      = true
  map_public_ip_on_launch   = false
  
  tags = {
    Terraform   = "true"
    Environment = "sandbox"
  }
}
