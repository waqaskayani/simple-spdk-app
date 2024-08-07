resource "aws_iam_role" "admin_asg_role" {
  name = "${var.default_name}-admin-asg-role"

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

resource "aws_iam_instance_profile" "admin_asg_instance_profile" {
  name = "${var.default_name}-admin-asg-instance-profile"
  role = aws_iam_role.admin_asg_role.name
}

resource "aws_iam_role_policy_attachment" "admin_asg_role_policy" {
  role       = aws_iam_role.admin_asg_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
