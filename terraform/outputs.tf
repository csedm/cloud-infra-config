output "aws_instance_public_ipv4_address" {
  description = "The public IPv4 address of the AWS instance"
  value       = aws_instance.alpine_image_test.public_ip
}