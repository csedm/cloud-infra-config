provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Origin_Repo     = var.origin_repo
      Environment     = "dev"
    }
  }
}

data "aws_ami" "alpine_custom_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["alpine-${var.ami_base_version}-${var.ami_architecture}-bios-cloudinit-custom*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.aws_ami_owner_id]
}

resource "aws_key_pair" "alpine_image_test_key" {
  key_name   = "alpine-image-test-key"
  public_key = file(var.aws_key_pair_path)
}

resource "aws_security_group" "alpine_image_test_sg" {
  name = "alpine-image-test-sg"

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

resource "aws_instance" "alpine_image_test" {
  ami                    = data.aws_ami.alpine_custom_ami.id
  instance_type          = var.aws_instance_type
  key_name               = aws_key_pair.alpine_image_test_key.key_name
  vpc_security_group_ids = [aws_security_group.alpine_image_test_sg.id]

  associate_public_ip_address = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  tags = {
    Name = "alpine-image-test"
    ansible_roles = "test"
  }

  # Need to fix this.
  # Prevent user being locked and therefore unable to login.
  user_data = templatefile("cloud-init.yml", { ssh_key = file(var.aws_key_pair_path) })
}
