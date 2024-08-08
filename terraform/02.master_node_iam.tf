resource "aws_iam_role" "master_asg_role" {
  name = "${var.default_name}-master-asg-role"

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

resource "aws_iam_role_policy" "master_asg_ssm_role" {
  name = "${var.default_name}-master-asg-ssm-policy"
  role = aws_iam_role.master_asg_role.id

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ],
        "Resource": [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/k3s/server/node-token",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/k3s/server/node-ip"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "master_asg_instance_profile" {
  name = "${var.default_name}-master-asg-instance-profile"
  role = aws_iam_role.master_asg_role.name
}

resource "aws_iam_role_policy_attachment" "master_asg_role_policy" {
  role       = aws_iam_role.master_asg_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
