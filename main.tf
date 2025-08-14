# main.tf

# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM SETTINGS
# ---------------------------------------------------------------------------------------------------------------------

# We define the minimum Terraform version and the required providers here.
# For more information, see: https://www.terraform.io/language/settings
# We'll use the latest Terraform version and a specific AWS provider version to ensure
# compatibility and stability.
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

# The AWS provider is configured here. We use a variable for the region, which we defined below,
# so that the code can be easily reused in different regions without modification.
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

# A data source is a resource that "fetches" data rather than creating it.
# This data source finds the most recent Ubuntu 20.04 LTS AMI, which is much better than
# hard-coding an AMI ID that might become outdated or not work in all regions.
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # Canonical's AWS account ID for Ubuntu images
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# RESOURCES
# ---------------------------------------------------------------------------------------------------------------------

# This resource generates a private key that we can use for SSH access.
# For more information, see: https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
resource "tls_private_key" "dev-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# This resource uploads the public key from the tls_private_key resource to AWS.
# The `provisioner` block creates a local file with the private key for us to use.
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "dev-key-pair" {
  key_name   = "dev-key-pair"
  public_key = tls_private_key.dev-key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.dev-key.private_key_pem}' > ./dev-key-pair.pem"
  }
}

# This resource creates the EC2 instance itself. We're now using a data source for the AMI
# and a variable for the instance type, making the resource block much more dynamic.
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "example" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = "dev-key-pair"
  vpc_security_group_ids      = [aws_security_group.instance.id]
  user_data                   = <<-EOF
              #!/bin/bash
              echo "Hola, Mundo! <br> Welcome to your workstation!" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  user_data_replace_on_change = true

  tags = {
    Name = "terraform-dev"
  }
}

# This resource creates a security group to act as a firewall for the EC2 instance.
# We're using a variable for the name, as you already had.
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
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

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

# A variable is a named value that can be passed into a Terraform module.
# We've added a few here to make the code more configurable and reusable.
# For more information, see: https://www.terraform.io/language/values/variables
variable "aws_region" {
  description = "AWS cloud region to deploy resources to."
  type        = string
  default     = "us-west-2"
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-dev-instance"
}

variable "instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

# Outputs are values that can be displayed on the console after `terraform apply`.
# We'll keep the outputs you already had, as they're very useful for accessing the instance.
# For more information, see: https://www.terraform.io/language/values/outputs
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
