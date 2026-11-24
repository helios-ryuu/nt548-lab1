output "public_sg_id" {
  description = "ID of the Public EC2 Security Group"
  value       = aws_security_group.public_ec2.id
}

output "private_sg_id" {
  description = "ID of the Private EC2 Security Group"
  value       = aws_security_group.private_ec2.id
}
