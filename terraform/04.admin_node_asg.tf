resource "aws_launch_template" "launch_template_admin" {
  name          = var.launch_template_name_admin
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_admin

  network_interfaces {
    associate_public_ip_address = var.enable_public_ip
    security_groups             = [aws_security_group.admin_asg_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.admin_asg_instance_profile.name
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

    cat <<EOT > /etc/systemd/system/hugepages.service
    [Unit]
    Description=Allocate Huge Pages
    DefaultDependencies=no
    After=local-fs.target

    [Service]
    Type=oneshot
    ExecStart=/usr/sbin/sysctl -w vm.nr_hugepages=256

    [Install]
    WantedBy=basic.target
    EOT

    systemctl daemon-reload
    systemctl start hugepages
    systemctl enable hugepages

    # Load necessary kernel module
    modprobe vfio-pci

    apt update -y && apt install unzip -y

    # Install AWS CLI for ECR
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # Install docker
    apt install -y docker.io
    sleep 3
    usermod -aG docker ssm-user
    newgrp docker
    EOF
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ module.vpc ]
}

resource "aws_autoscaling_group" "asg_admin" {
  launch_template {
    id      = aws_launch_template.launch_template_admin.id
    version = "$Latest"
  }

  name                = "${var.default_name}-admin-node-asg"
  vpc_zone_identifier = var.enable_public_ip ? module.vpc.public_subnets : module.vpc.private_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  tag {
    key                 = "Name"
    value               = "${var.default_name}-admin-node"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 180
}

resource "aws_security_group" "admin_asg_sg" {
  name        = "${var.default_name}-admin-asg-sg"
  description = "Security group for the admin node ASG"
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
    Name = "${var.default_name}-admin-asg-sg"
  }
}
