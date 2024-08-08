# SSM Parameter store secure string for K3s node token and ip
resource "aws_ssm_parameter" "k3s_node_token" {
    name  = "/k3s/server/node-token"
    type  = "SecureString"
    value = "placeholder"

  lifecycle {
    ignore_changes = [value]                // Ignoring changes to the value, since it will be managed by Master ASG Node
  }
}

resource "aws_ssm_parameter" "k3s_node_ip" {
    name  = "/k3s/server/node-ip"
    type  = "SecureString"
    value = "placeholder"

  lifecycle {
    ignore_changes = [value]
  }
}
