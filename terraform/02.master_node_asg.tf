resource "aws_launch_template" "launch_template_master" {
  name          = var.launch_template_name_master
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_master

  network_interfaces {
    associate_public_ip_address = var.enable_public_ip
    security_groups             = [aws_security_group.master_asg_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.master_asg_instance_profile.name
  }

  block_device_mappings {
    device_name = tolist(data.aws_ami.ubuntu.block_device_mappings)[0].device_name
    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    apt update -y && apt install unzip jq -y
    snap install yq

    # Install AWS CLI for ECR
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # Install K3s master server
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

    # Ensure all nodes are up and running then taint master nodes for NoSchedule
    kubectl wait --for=condition=Ready node --all --timeout=60s
    kubectl get nodes -o json | jq -r '.items[] | select(.metadata.labels["node-role.kubernetes.io/control-plane"] != null) | .metadata.name' | xargs -I {} kubectl taint nodes {} node-role.kubernetes.io/control-plane=:NoSchedule

    # Read node token and ip and store it in Parameter Store
    NODE_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
    NODE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    aws ssm put-parameter --name "/k3s/server/node-token" --value "$NODE_TOKEN" --type "SecureString" --overwrite --region ${var.region}
    aws ssm put-parameter --name "/k3s/server/node-ip" --value "$NODE_IP" --type "SecureString" --overwrite --region ${var.region}
    EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_master" {
  launch_template {
    id      = aws_launch_template.launch_template_master.id
    version = "$Latest"
  }

  name                = "${var.default_name}-master-node-asg"
  vpc_zone_identifier = module.vpc.public_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  tag {
    key                 = "Name"
    value               = "${var.default_name}-master-node"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 180
}

data "aws_instances" "asg_master" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.asg_master.name]
  }
}

output "master_instance_ids" {
  value = data.aws_instances.asg_master.ids
}

resource "aws_security_group" "master_asg_sg" {
  name        = "${var.default_name}-master-asg-sg"
  description = "Security group for the Master node ASG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["92.98.172.238/32"]
    description = "Allow incoming traffic from home ip"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["13.52.6.112/29"]
    description = "Allow incoming ssh from Instance Connect IPs"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ var.vpc_cidr ]
    description = "Allow incoming traffic from VPC private IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.default_name}-master-asg-sg"
  }
}
