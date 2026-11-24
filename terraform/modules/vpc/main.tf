# ==============================================================================
# Module VPC — Hạ tầng mạng lõi (10 tài nguyên)
# ==============================================================================

# 1. Tạo VPC chính với dải mạng 10.0.0.0/16, bật DNS để phân giải tên miền nội bộ & public
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Quản lý Default Security Group mặc định của VPC và đóng sạch toàn bộ ingress/egress
#    (giảm bề mặt tấn công & đạt chuẩn bảo mật Checkov CKV2_AWS_12 cho Lab 02)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-default-sg-restricted"
  }
}

# 3. Internet Gateway (IGW) — cổng kết nối 2 chiều giữa VPC và Internet
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 4. Public Subnet (10.0.1.0/24) — tự động cấp Public IP cho tài nguyên đặt bên trong
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "Public"
  }
}

# 5. Private Subnet (10.0.2.0/24) — KHÔNG cấp Public IP, cách ly hoàn toàn khỏi Internet chiều vào
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet"
    Tier = "Private"
  }
}

# 6. Elastic IP (EIP) — địa chỉ IP công cộng tĩnh gắn cho NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# 7. NAT Gateway — đặt trong Public Subnet, giúp Private Subnet truy cập Internet chiều đi (outbound)
#    Phải đợi IGW gắn xong vào VPC trước khi tạo (depends_on)
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.this]
}

# 8. Public Route Table — định tuyến lưu lượng ra ngoài Internet (0.0.0.0/0) qua IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# 9. Gắn Public Route Table vào Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 10. Private Route Table — định tuyến lưu lượng outbound (0.0.0.0/0) qua NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# 11. Gắn Private Route Table vào Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
