output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "default_security_group_id" {
  description = "ID of the VPC Default Security Group (restricted)"
  value       = module.vpc.default_security_group_id
}

output "public_subnet_id" {
  description = "ID of the Public Subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the Private Subnet"
  value       = module.vpc.private_subnet_id
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

output "nat_eip" {
  description = "Elastic IP attached to the NAT Gateway"
  value       = module.vpc.nat_eip
}

output "public_sg_id" {
  description = "ID of the Public EC2 Security Group"
  value       = module.security_group.public_sg_id
}

output "private_sg_id" {
  description = "ID of the Private EC2 Security Group"
  value       = module.security_group.private_sg_id
}

output "public_ec2_id" {
  description = "Instance ID of the Public EC2 (Bastion)"
  value       = module.ec2.public_ec2_id
}

output "public_ec2_public_ip" {
  description = "Public IP of the Public EC2 (Bastion)"
  value       = module.ec2.public_ec2_public_ip
}

output "public_ec2_private_ip" {
  description = "Private IP of the Public EC2 (Bastion)"
  value       = module.ec2.public_ec2_private_ip
}

output "private_ec2_id" {
  description = "Instance ID of the Private EC2"
  value       = module.ec2.private_ec2_id
}

output "private_ec2_private_ip" {
  description = "Private IP of the Private EC2"
  value       = module.ec2.private_ec2_private_ip
}

output "ssh_public_command" {
  description = "Command to SSH into Public EC2"
  value       = "ssh -i ~/.ssh/labsuser.pem ec2-user@${module.ec2.public_ec2_public_ip}"
}

output "ssh_private_proxyjump_command" {
  description = "Command to SSH into Private EC2 via Bastion ProxyJump"
  value       = "ssh -i ~/.ssh/labsuser.pem -J ec2-user@${module.ec2.public_ec2_public_ip} ec2-user@${module.ec2.private_ec2_private_ip}"
}
