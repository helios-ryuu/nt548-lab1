# ==============================================================================
# Cấu hình phiên bản Terraform & AWS Provider
# ==============================================================================
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Khóa cứng Region mặc định us-east-1 cho AWS Academy Learner Lab
# và gắn nhãn (default_tags) tự động cho toàn bộ tài nguyên tạo ra
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Course    = "NT548"
    }
  }
}
