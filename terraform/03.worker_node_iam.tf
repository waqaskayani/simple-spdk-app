resource "aws_iam_role" "worker_asg_role" {
  name = "${var.default_name}-worker-asg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_asg_role_policy" {
  role       = aws_iam_role.worker_asg_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Terraform IAM policy resource to read ECR repository and pull container images
resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "${var.default_name}-ecr-pull-policy"
  description = "Policy to read ECR repository and pull container images"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"        
        ]
        "Resource": "${aws_ecr_repository.spdk_ecr_repository.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
        ]
        "Resource": "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "worker_asg_ssm_role" {
  name = "${var.default_name}-worker-asg-ssm-policy"
  role = aws_iam_role.worker_asg_role.id

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/k3s/server/node-token"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "ecr_pull_policy_attachment" {
  role       = aws_iam_role.worker_asg_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

resource "aws_iam_instance_profile" "worker_asg_instance_profile" {
  name = "${var.default_name}-worker-asg-instance-profile"
  role = aws_iam_role.worker_asg_role.name
}
