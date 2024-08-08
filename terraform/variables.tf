variable "region" {
  description = "The AWS region to create resources in"
  default     = "us-west-1"
}

variable "default_name" {
  description = "Name of the project used for resources as default"
  type        = string
  default     = "simplyblock"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "launch_template_name_master" {
  description = "Name of master launch template"
  type        = string
  default     = "simplyblock-lt-master"  
}

variable "instance_type_master" {
  description = "Instance type of master node pool"
  type        = string
  default     = "t3a.small"  
}

variable "launch_template_name_worker" {
  description = "Name of worker launch template"
  type        = string
  default     = "simplyblock-lt-worker"  
}

variable "instance_type_worker" {
  description = "Instance type of worker node pool"
  type        = string
  default     = "t3a.small"  
}

variable "launch_template_name_admin" {
  description = "Name of admin launch template"
  type        = string
  default     = "simplyblock-lt-admin"  
}

variable "instance_type_admin" {
  description = "Instance type of admin node pool"
  type        = string
  default     = "t3a.small"  
}

variable "enable_public_ip" {
  description = "Enable public ip for nodes"  
  type           = bool
  default        = false
}
