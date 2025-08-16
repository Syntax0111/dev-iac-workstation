# main.tf

# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM SETTINGS
# ---------------------------------------------------------------------------------------------------------------------

# Define the minimum Terraform version and the required providers here.
# For more information, see: https://www.terraform.io/language/settings
# Use the latest Terraform version and a specific AWS provider version to ensure
# compatibility and stability.
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region  = var.aws_region
  profile = "AdminJorge"
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------

# This data source finds the most recent Ubuntu 20.04 LTS AMI
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

# This data source looks up the existing key pair by its name.
# This allows the aws_instance resource to reference the key without having to create it.
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/key_pair
data "aws_key_pair" "dev-key-pair" {
  key_name = "dev-key-pair"
}

# ---------------------------------------------------------------------------------------------------------------------
# RESOURCES
# ---------------------------------------------------------------------------------------------------------------------

# This resource creates the EC2 instance
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "example" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.dev-key-pair.key_name
  vpc_security_group_ids = [aws_security_group.instance.id]
  tags = {
    Name = "terraform-dev"
  }
}

# This resource creates a security group to act as a firewall for the EC2 instance.
# The only inbound traffic we're allowing is for SSH (port 22).
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "instance" {
  name = var.security_group_name

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
