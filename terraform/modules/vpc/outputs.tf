output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "default_security_group_id" {
  description = "ID of the restricted Default Security Group"
  value       = aws_default_security_group.default.id
}

output "public_subnet_id" {
  description = "ID of the Public Subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the Private Subnet"
  value       = aws_subnet.private.id
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "nat_eip" {
  description = "Public Elastic IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}
