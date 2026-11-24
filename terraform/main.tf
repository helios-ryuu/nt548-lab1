# ==============================================================================
# Root Module — Điều phối 3 module hạ tầng: vpc -> security_group -> ec2
# ==============================================================================

# 1. Module Mạng: tạo VPC, Default SG (đóng rule), IGW, Public/Private Subnets,
#    EIP, NAT Gateway và Public/Private Route Tables
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  availability_zone   = var.availability_zone
}

# 2. Module Bảo mật: tạo Public EC2 SG (chỉ SSH từ /32) và Private EC2 SG (chỉ SSH từ Public SG)
module "security_group" {
  source = "./modules/security_group"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip_cidr   = var.my_ip_cidr
}

# 3. Module Máy chủ: tạo Public EC2 (Bastion) và Private EC2 (Internal)
#    với Amazon Linux 2023, IMDSv2 và EBS mã hóa
module "ec2" {
  source = "./modules/ec2"

  project_name      = var.project_name
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  public_sg_id      = module.security_group.public_sg_id
  private_sg_id     = module.security_group.private_sg_id
  key_name          = var.key_name
  instance_type     = var.instance_type
}
