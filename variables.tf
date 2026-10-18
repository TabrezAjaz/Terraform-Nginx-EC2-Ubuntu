variable "aws_region" {
  description = "AWS region used for the deployment."
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile; null uses the standard credential chain."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "EC2 instance type required by the assignment."
  type        = string
  default     = "t2.micro"

  validation {
    condition     = var.instance_type == "t2.micro"
    error_message = "The assignment requires instance_type to remain t2.micro."
  }
}

variable "admin_cidr" {
  description = "Administrator public IPv4 CIDR allowed to connect over SSH."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid restricted CIDR and cannot be 0.0.0.0/0."
  }
}

variable "key_name" {
  description = "Existing EC2 key-pair name in the selected AWS region."
  type        = string
}
