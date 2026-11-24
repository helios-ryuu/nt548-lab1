variable "project_name" {
  description = "Prefix name for EC2 resources"
  type        = string
}

variable "public_subnet_id" {
  description = "Subnet ID for Public EC2"
  type        = string
}

variable "private_subnet_id" {
  description = "Subnet ID for Private EC2"
  type        = string
}

variable "public_sg_id" {
  description = "Security Group ID for Public EC2"
  type        = string
}

variable "private_sg_id" {
  description = "Security Group ID for Private EC2"
  type        = string
}

variable "key_name" {
  description = "AWS EC2 Key Pair name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
