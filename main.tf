provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "./modules/network"

  bastion_instance_type = var.bastion_instance_type
}

resource "aws_security_group" "bastion" {
  name   = "bastion_ssh"
  vpc_id = module.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Example CIDR
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  instance_type = var.bastion_instance_type
  ami           = data.aws_ami.amazon_linux.id

  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]


  lifecycle {
    precondition {
      condition     = data.aws_ec2_instance_type.bastion.default_cores <= 2
      error_message = "Change the value of bastion_instance_type to a type that has fewer than 2 cores to avoid over provisioning."
    }
}

data "aws_ec2_instance_type" "bastion" {
  instance_type = var.bastion_instance_type
}

