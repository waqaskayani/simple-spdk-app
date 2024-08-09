module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.default_name
  cidr = var.vpc_cidr

  # Creating Private/Public subnets based on Enabled public IPs
  azs                       = ["us-west-1a", "us-west-1b"]
  public_subnets            = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets           = ["10.0.103.0/24", "10.0.104.0/24"]
  enable_nat_gateway        = !var.enable_public_ip
  single_nat_gateway        = !var.enable_public_ip

  public_route_table_tags   = {
    Name = "${var.default_name}-public-rt"
  }
  private_route_table_tags   = {
    Name = "${var.default_name}-private-rt"
  }

  enable_dns_hostnames      = true
  map_public_ip_on_launch   = var.enable_public_ip

  tags = {
    Terraform   = "true"
    Environment = "sandbox"
  }
}
