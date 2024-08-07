resource "aws_launch_template" "launch_template_worker" {
  name          = var.launch_template_name_worker
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_worker

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.worker_asg_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_asg_instance_profile.name
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

    # Create the systemd service file for Transparent hugepage and Allocating hugepage
    cat <<EOT > /etc/systemd/system/enable-thp.service
    [Unit]
    Description=Enable Transparent Huge Pages
    DefaultDependencies=no
    After=sysinit.target local-fs.target

    [Service]
    Type=oneshot
    ExecStart=/bin/sh -c 'echo always | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'

    [Install]
    WantedBy=basic.target
    EOT

    cat <<EOT > /etc/systemd/system/hugepages.service
    [Unit]
    Description=Allocate Huge Pages
    DefaultDependencies=no
    After=local-fs.target

    [Service]
    Type=oneshot
    ExecStart=/usr/sbin/sysctl -w vm.nr_hugepages=2048

    [Install]
    WantedBy=basic.target
    EOT

    systemctl daemon-reload
    systemctl start enable-thp hugepages
    systemctl enable enable-thp hugepages

    # Load necessary kernel module
    modprobe vfio-pci

    apt update -y && apt install unzip -y

    # Install AWS CLI for ECR
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # Fetch the node token from Parameter Store and join the K3s cluster
    NODE_TOKEN=$(aws ssm get-parameter --name "/k3s/server/node-token" --with-decryption --query "Parameter.Value" --output text --region ${var.region})
    curl -sfL https://get.k3s.io | K3S_URL=https://${data.aws_instances.asg_master.private_ips[0]}:6443 K3S_TOKEN=$NODE_TOKEN sh -

    # Add ECR repo login for K3s
    ECR_TOKEN=$(aws ecr get-login-password --region ${var.region})
    REPO_URL=$(echo ${aws_ecr_repository.spdk_ecr_repository.repository_url} | cut -d'/' -f1)

    mkdir -p /etc/rancher/k3s
    sudo cat<<EOF2 >> /etc/rancher/k3s/registries.yaml
    configs:
      $REPO_URL:
        auth:
            username: AWS
            password: $ECR_TOKEN
    EOF2
    systemctl force-reload k3s-agent
    sleep 2
    systemctl status k3s-agent

  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_worker" {
  launch_template {
    id      = aws_launch_template.launch_template_worker.id
    version = "$Latest"
  }

  name                = "${var.default_name}-worker-node-asg"
  vpc_zone_identifier = module.vpc.public_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  tag {
    key                 = "Name"
    value               = "${var.default_name}-worker-node"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 180

  depends_on = [ aws_autoscaling_group.asg_master ]
}

data "aws_instances" "asg_worker" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.asg_worker.name]
  }
}

output "worker_instance_ids" {
  value = data.aws_instances.asg_worker.ids
}

resource "aws_security_group" "worker_asg_sg" {
  name        = "${var.default_name}-worker-asg-sg"
  description = "Security group for the worker node ASG"
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
    Name = "${var.default_name}-worker-asg-sg"
  }
}
