terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

#    backend "s3" {
#     bucket         = "artac-terraform-state-edenbarkan"
#     key            = "artac/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "artac-terraform-locks"
#     encrypt        = true
#   }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user-data.sh", {
    docker_image = var.docker_image
    app_port     = var.app_port
  })

  tags = {
    Name    = "artac-app-server"
    Project = "ArtAc"
  }
}

resource "null_resource" "update_github_secret" {
  triggers = {
    instance_ip = aws_instance.app_server.public_ip
  }

  provisioner "local-exec" {
    command = "gh secret set EC2_HOST --body '${aws_instance.app_server.public_ip}' --repo ${var.github_repo}"
  }
}