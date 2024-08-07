# SSM Parameter store secure string for K3s node token
resource "aws_ssm_parameter" "k3s_node_token" {
    name  = "/k3s/server/node-token"
    type  = "SecureString"
    value = "placeholder"

  lifecycle {
    ignore_changes = [value]
  }
}
