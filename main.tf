terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Mock credentials: this config is NEVER applied. Terraform plan works offline
# and Infracost reads prices from its own pricing API.
provider "aws" {
  region                      = "eu-north-1" # Stockholm
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}

resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = "vpc-12345678" # dummy, avoids default-VPC lookup

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count                  = var.instance_count
  ami                    = "ami-0123456789abcdef0" # fake, never launched
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = <<-USERDATA
    #!/bin/bash
    dnf install -y nginx
    echo "<h1>Cost-aware infra demo</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  USERDATA

  tags = {
    Name = "web-${count.index}"
  }
}
