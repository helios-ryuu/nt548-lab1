# ==============================================================================
# Module Security Group — Tường lửa mức Instance cho Public EC2 & Private EC2
# ==============================================================================

# 1. Security Group cho Public EC2 (Bastion Host)
#    - Inbound : chỉ mở SSH (TCP 22) từ đúng Public IP máy cá nhân (<MY_IP>/32)
#    - Outbound: cho phép toàn bộ chiều đi (cần thiết để SSH ProxyJump sang Private EC2 & cập nhật gói)
resource "aws_security_group" "public_ec2" {
  name        = "${var.project_name}-public-ec2-sg"
  description = "Allow SSH inbound only from personal IP (/32)"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from personal IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-public-ec2-sg"
  }
}

# 2. Security Group cho Private EC2 (Internal Server)
#    - Inbound : chỉ cho phép SSH (TCP 22) từ Public EC2 SG (Security Group chaining)
#    - Outbound: cho phép toàn bộ chiều đi qua NAT Gateway (phục vụ test curl/HTTPS/DNS/ping)
resource "aws_security_group" "private_ec2" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Allow SSH inbound only from Public EC2 Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from Public EC2 Security Group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  egress {
    description = "Allow all outbound traffic via NAT Gateway (HTTP/HTTPS/DNS/ICMP)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-ec2-sg"
  }
}
