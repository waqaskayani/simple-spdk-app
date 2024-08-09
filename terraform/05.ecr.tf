# ECR repository for storing SPDK container images
resource "aws_ecr_repository" "spdk_ecr_repository" {
    name                 = var.default_name
    image_tag_mutability = "MUTABLE"

    # Run `aws ecr delete-repository --repository-name simplyblock --force` on AWS CLI if facing issues with deletion
    force_delete         = true
}
