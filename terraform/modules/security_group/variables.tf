variable "project_name" {
  description = "Prefix name for Security Group resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Security Groups will be created"
  type        = string
}

variable "my_ip_cidr" {
  description = "Personal public IP in /32 CIDR format allowed to SSH into Public EC2"
  type        = string
}
