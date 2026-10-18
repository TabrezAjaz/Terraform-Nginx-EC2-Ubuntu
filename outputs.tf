output "public_ip" {
  description = "Public IPv4 address of the Terraform-managed Nginx server."
  value       = aws_instance.nginx.public_ip
}

output "nginx_url" {
  description = "Public URL of the custom Nginx page."
  value       = "http://${aws_instance.nginx.public_ip}"
}

output "instance_id" {
  description = "EC2 instance identifier."
  value       = aws_instance.nginx.id
}

output "default_vpc_id" {
  description = "Existing default VPC used by the instance."
  value       = data.aws_vpc.default.id
}
