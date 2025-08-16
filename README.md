# Software Development Workstation

> **Note**: </br>
> The following assumes [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [Terraform](https://developer.hashicorp.com/terraform/install) are installed and configured.

## **Provision a Private Key**
```shell
cd key-management
terraform init
terraform apply
```

## **Provision the Ubuntu EC2 Instance using Terraform**

Apply the Infrastructure Deployment Terraform script
```shell
cd infra-deployment
terraform init
terraform apply
```

Destroy
```shell
cd infra-deployment
terraform destroy
```

```shell
cd key-management
terraform destroy
```

## Connect to the EC2 Instance using SSH

Change permissions for the `.pem` file
```shell
chmod 400 ./key-management/dev-key-pair.pem
```

Connect using `ssh`
```shell
ssh -i key-management/dev-key-pair.pem <user>@<public-dns or public-ip>
```

Update Ubuntu Repositories

```shell
sudo apt-get update
```

Install Docker Engine

- https://docs.docker.com/engine/install/ubuntu/#prerequisites

Install Airflow Docker Containers

Install Prometheus Docker Container

Install Grafana Docker Container

Install NGINX Docker Container

- https://www.docker.com/blog/how-to-use-the-official-nginx-docker-image/
- https://hub.docker.com/_/nginx

Data Engineering Pipeline Workflows

- MLOps
- Sensors for Autonomous Systems/Robotics