variable "origin_repo" {
  description = "The repository name in which this code originates."
  type        = string
  default     = "cloud-infra-config"
}
variable "aws_region" {
  description = "The AWS region to deploy the resources in"
  type        = string
  default     = "us-east-1"
}
variable "aws_instance_type" {
  description = "The type of AWS instance to use"
  type        = string
  default     = "t2.micro"
}
variable "aws_ssh_authorized_keys" {
  description = "The public ssh keys to authorize for the instance(s)."
  type        = list(map(string))
}
variable "aws_ami_owner_id" {
  description = "Owner ID of the AMI"
  type        = string
}
variable "ami_base_version" {
  description = "Base version of the AMI"
  type        = string
  default     = "3.21"
}
variable "ami_architecture" {
  description = "Architecture of the AMI (x86_64 or arm64)"
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.ami_architecture)
    error_message = "The ami_architecture variable must be either 'x86_64' or 'arm64'."
  }
}
variable "custom_default_user" {
  description = "The custom default user for the AMI"
  type        = string
}