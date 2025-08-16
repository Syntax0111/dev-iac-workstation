# key_generator.tf

# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM SETTINGS
# ---------------------------------------------------------------------------------------------------------------------

# We define the minimum Terraform version and the required providers here.
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

# The AWS provider is configured here, but without a region since this script is
# not region-specific. The `aws_key_pair` resource can be created in any region.
provider "aws" {
  region  = "us-west-2"
  profile = "AdminJorge"
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
# The `provisioner` block creates a local file with the private key.
# For more information, see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "dev-key-pair" {
  key_name   = "dev-key-pair"
  public_key = tls_private_key.dev-key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.dev-key.private_key_pem}' > ./dev-key-pair.pem"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

# Outputs are used to display key information after `terraform apply`.
# We'll output the public and private keys, as well as the name of the key pair.
# This makes it easy to confirm that the key was created.
# For more information, see: https://www.terraform.io/language/values/outputs
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
