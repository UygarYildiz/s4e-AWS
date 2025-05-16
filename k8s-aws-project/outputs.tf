output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.k8s_server.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.k8s_server.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.k8s_sg.id
}
