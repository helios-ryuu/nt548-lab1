output "public_ec2_id" {
  description = "Instance ID of the Public EC2"
  value       = aws_instance.public.id
}

output "public_ec2_public_ip" {
  description = "Public IP of the Public EC2"
  value       = aws_instance.public.public_ip
}

output "public_ec2_private_ip" {
  description = "Private IP of the Public EC2"
  value       = aws_instance.public.private_ip
}

output "private_ec2_id" {
  description = "Instance ID of the Private EC2"
  value       = aws_instance.private.id
}

output "private_ec2_private_ip" {
  description = "Private IP of the Private EC2"
  value       = aws_instance.private.private_ip
}
