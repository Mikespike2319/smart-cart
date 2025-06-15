terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "maxsaver-pro-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}

# RDS Database
module "rds" {
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  db_password  = var.db_password
}

# ElastiCache (Redis)
module "elasticache" {
  source = "./modules/elasticache"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}

# Elasticsearch
module "elasticsearch" {
  source = "./modules/elasticsearch"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnet_ids
}

# CloudFront Distribution
module "cloudfront" {
  source = "./modules/cloudfront"
  
  project_name = var.project_name
  environment  = var.environment
  alb_dns_name = module.alb.dns_name
}

# S3 Buckets
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  eks_cluster_name = module.eks.cluster_name
}

# CloudWatch Logs
module "cloudwatch" {
  source = "./modules/cloudwatch"
  
  project_name = var.project_name
  environment  = var.environment
}

# Route53
module "route53" {
  source = "./modules/route53"
  
  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  cloudfront_distribution_id = module.cloudfront.distribution_id
}

# ACM Certificate
module "acm" {
  source = "./modules/acm"
  
  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
}

# WAF
module "waf" {
  source = "./modules/waf"
  
  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.alb.arn
}

# Backup
module "backup" {
  source = "./modules/backup"
  
  project_name = var.project_name
  environment  = var.environment
  rds_instance_id = module.rds.instance_id
}

# Monitoring and Alerting
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name = var.project_name
  environment  = var.environment
  eks_cluster_name = module.eks.cluster_name
  rds_instance_id = module.rds.instance_id
} 