variable "project_name" {
  description = "Prefix name for all AWS resources"
  type        = string
  default     = "nt548-lab1"
}

variable "aws_region" {
  description = "AWS region (locked to us-east-1 for AWS Academy Learner Lab)"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability Zone for Public and Private Subnets"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the Private Subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "my_ip_cidr" {
  description = "Personal public IP in CIDR notation (<MY_IP>/32) allowed to SSH into Public EC2"
  type        = string
}

variable "key_name" {
  description = "Existing AWS EC2 Key Pair name (default vockey for Learner Lab)"
  type        = string
  default     = "vockey"
}

variable "instance_type" {
  description = "EC2 instance type for Public and Private instances"
  type        = string
  default     = "t3.micro"
}
