# ==============================================================================
# Module EC2 — Triển khai 1 Public EC2 (Bastion) & 1 Private EC2 (Internal)
# ==============================================================================

# Tự động tra cứu AMI mới nhất của Amazon Linux 2023 (x86_64, HVM) tại region hiện tại
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. Public EC2 (Bastion Host) — nằm trong Public Subnet, có Public IP để SSH từ máy cá nhân
resource "aws_instance" "public" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.public_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Bắt buộc IMDSv2 để chống lỗ hổng SSRF (tương thích chuẩn bảo mật Lab 02)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Mã hóa ổ đĩa gốc EBS (gp3, 8GB)
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "${var.project_name}-public-ec2"
    Tier = "Public"
  }
}

# 2. Private EC2 (Internal Server) — nằm trong Private Subnet, KHÔNG có Public IP
#    Chỉ có thể truy cập qua SSH ProxyJump từ Public EC2 và ra Internet qua NAT Gateway
resource "aws_instance" "private" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [var.private_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  # Bắt buộc IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Mã hóa ổ đĩa gốc EBS (gp3, 8GB)
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "${var.project_name}-private-ec2"
    Tier = "Private"
  }
}
