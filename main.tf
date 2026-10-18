terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = "terraform-nginx-ubuntu"
      ManagedBy = "Terraform"
      Owner     = "Tabrez Ajaz"
    }
  }
}

# The assignment explicitly requires the account's existing default VPC.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest official Canonical Ubuntu 20.04 LTS (Focal) x86_64 AMI.
data "aws_ami" "ubuntu_2004" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nginx" {
  name_prefix = "terraform-nginx-"
  description = "Allow public HTTP and restricted SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Public HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from administrator IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Required package downloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "terraform-nginx-sg" }
}

resource "aws_instance" "nginx" {
  ami                         = data.aws_ami.ubuntu_2004.id
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.nginx.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y nginx
    cat > /var/www/html/index.html <<'HTML'
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <title>Terraform-managed Nginx</title>
      <style>
        body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #0f172a; color: #f8fafc; font-family: Arial, sans-serif; }
        main { max-width: 760px; padding: 48px; border-left: 6px solid #22d3ee; background: #172554; box-shadow: 0 20px 50px #0008; }
        h1 { margin: 0 0 16px; font-size: 42px; line-height: 1.15; }
        p { margin: 0; color: #a5f3fc; font-size: 18px; }
      </style>
    </head>
    <body><main><h1>Welcome to the Terraform-managed Nginx Server on Ubuntu</h1><p>Provisioned with Terraform · Served by Nginx</p></main></body>
    </html>
    HTML
    systemctl enable nginx
    systemctl restart nginx
  EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 8
  }

  tags = { Name = "terraform-nginx-ubuntu" }
}
