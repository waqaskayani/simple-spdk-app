# ECR repository for storing SPDK container images
resource "aws_ecr_repository" "spdk_ecr_repository" {
    name                 = var.default_name
    image_tag_mutability = "MUTABLE"
}
