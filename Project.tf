# Definition of a provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.60.0"
    }
  }
}

# Provider Configuration
provider "aws" {
  profile = "terraform_den"  # Get profile from .aws/config
  region  = "us-west-2"
}

# Variables
variable "instance_size" {
  type    = string
  default = "t3.medium"
}

variable "public_key" {
  description = "Your new public SSH key"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLCmY2q6VoJTjbiN3sCQZ/MzODi6Du1Jt21lcFucmGQTUsmMJK+yxO5NyLXtCdmNFaIyV3VrLponeDrsbPQIhgXNqCqtR9QppPk89qSIyGNm6Y5D1NnsV9SvXNBZXeuxfsXezU6wqFwtRcaAP2UhjNAV/RlWDBs7+er8vTPWTD/5SGaNxEm16rgVbmrXoq/SpwtpbyrXeUtN2H1Ol+4hALIrXM3rE6lUp4CeJ/K4XGi7PD1s81FPlLwdbbeA7mFLWnFZV08xRdybHH/hteDcDG52UxWer+icHCoWk6kV4hyiXNTYpTCQRvXGqrl5k5O/k5RfSAHlUBki9Pe/azFdlH denis@denis"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main_vpc"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "main_subnet"
  }
}

# Security Group
resource "aws_security_group" "main" {
  name        = "main_security_group"
  description = "Allow"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main_security_group"
  }
}

# AMI Data Source
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical
}

# EC2 Instance
resource "aws_instance" "my_ec2" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_size
  key_name             = aws_key_pair.deployer.key_name #"indus-key-name"
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id            = aws_subnet.main.id

  tags = {
    Name = "indus_ec2"
  }
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "indus-key-name"
  public_key = var.public_key
}
/*
# Elastic IP
resource "aws_eip" "lb" {
  domain = "vpc"

  tags = {
    Name = "Udemy"
  }
}

# Output
output "public-ip" {
  value = aws_eip.lb.public_ip
}
*/
