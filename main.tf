terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "tls_private_key" "dev-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "dev-key-pair" {
  key_name   = "dev-key-pair"
  public_key = tls_private_key.dev-key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.dev-key.private_key_pem}' > ./dev-key-pair.pem"
  }
}

resource "aws_instance" "example" {
  ami                    = "ami-075686beab831bb7f"
  instance_type          = "t2.micro"
  key_name               = "dev-key-pair"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hola, Mundo! <br> Welcome to your workstation!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-dev"
  }
}

resource "aws_security_group" "instance" {

  name = var.security_group_name

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-dev-instance"
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP of the Instance"
}

output "instance_public_key" {
  description = "Public key of dev-key-pair"
  value       = tls_private_key.dev-key.public_key_openssh
  sensitive   = true
}

output "instance_private_key" {
  description = "Private key of dev-key-pair"
  value       = tls_private_key.dev-key.public_key_pem
  sensitive   = true
}
