// Define the required Packer version
packer {
  required_version = ">= 1.12"
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "ami_base_version" {
  type    = string
  default = "3.21"
}
variable "ami_architecture" {
  type        = string
  description = "Architecture of the AMI (x86_64 or arm64)"
  default     = "x86_64"
  validation {
    condition     = contains(["x86_64", "arm64"], var.ami_architecture)
    error_message = "The ami_architecture variable must be either 'x86_64' or 'arm64'."
  }
}
variable "aws_ami_output_regions" {
  description = "List of regions to copy the AMI to"
  type        = list(string)
  default = [
    "us-east-1"
  ]
}
variable "build_type" {
  type        = string
  description = "Type of build (dev or prd)"
  default     = "dev"
  validation {
    condition     = contains(["dev", "prd"], var.build_type)
    error_message = "The build_type variable must be either 'dev' or 'prd'."
  }
}
variable "rename_default_user_to" {
  description = "The username to rename the default user to"
  type        = string
}

// Define the source block for the AWS EBS builder
source "amazon-ebs" "alpine" {
  ami_name      = "alpine-${var.ami_base_version}-${var.ami_architecture}-bios-cloudinit-custom-${var.build_type}-{{timestamp}}"
  instance_type = var.aws_instance_type
  region        = var.aws_region
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "alpine-${var.ami_base_version}*-${var.ami_architecture}-bios-cloudinit*"
      root-device-type    = "ebs"
    }
    owners      = ["538276064493"] # Official Alpine Linux AMI owner ID
    most_recent = true
  }
  ssh_username                = "alpine"
  associate_public_ip_address = true
  encrypt_boot                = true
  ami_regions                 = var.aws_ami_output_regions
  imds_support                = "v2.0"
  tags = {
    Name           = "alpine-${var.ami_base_version}-${var.ami_architecture}-bios-cloudinit-custom-${var.build_type}"
    BuildType      = var.build_type
    ReleaseVersion = "{{timestamp}}"
    OSVersion      = var.ami_base_version
    Architecture   = var.ami_architecture
    CreatedBy      = "Packer"
  }
}

// Define the build block
build {
  sources = ["source.amazon-ebs.alpine"]

  provisioner "shell" {
    # attempt to rename the default user on alpine
    inline = [
      "echo 'permit nopass alpine' | doas tee /etc/doas.d/packertmp.conf",
      "doas sed -i 's/alpine/${var.rename_default_user_to}/g' /etc/doas.conf",
      "doas cp -ar /home/alpine /home/${var.rename_default_user_to}",
      "doas sed -i 's/alpine/${var.rename_default_user_to}/g' /etc/passwd", # rename user, home directory
      "doas sed -i 's/^alpine:/${var.rename_default_user_to}:/' /etc/group", # rename group
      "doas sed -i 's/^alpine:/${var.rename_default_user_to}:/' /etc/shadow", # rename user in shadow
      "doas sed -i 's/:alpine$/:${var.rename_default_user_to}/' /etc/group", # correct default group name
    ]
  }

  provisioner "ansible" {
    playbook_file       = "../ansible/config-image.yml"
    inventory_directory = "../ansible/inventory"
    #extra_arguments = [ "-e", "ansible_user=${var.rename_default_user_to}" ]
  }

  provisioner "shell" {
    # finalize rename of default user on alpine
    inline = [
      "doas rm -rf /home/alpine",
      "doas rm -rf /etc/doas.d/packertmp.conf"
    ]
  }
}
