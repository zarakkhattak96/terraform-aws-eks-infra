terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = data.aws_availability_zones.available.names
  tags                 = var.tags
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr_block
  tags         = var.tags
}

module "iam" {
  source = "./modules/iam"

  project_name     = var.project_name
  enable_ssm_access = var.enable_ssm_access
  tags             = var.tags
}

module "eks" {
  source = "./modules/eks"

  project_name              = var.project_name
  cluster_role_arn          = module.iam.eks_cluster_role_arn
  node_group_role_arn       = module.iam.eks_node_group_role_arn
  subnet_ids                = module.vpc.private_subnet_ids
  cluster_security_group_id = module.security_groups.eks_cluster_sg_id
  kubernetes_version        = var.kubernetes_version
  node_group_desired_size   = var.node_group_desired_size
  node_group_max_size       = var.node_group_max_size
  node_group_min_size       = var.node_group_min_size
  node_instance_types       = var.node_instance_types
  node_capacity_type        = var.node_capacity_type
  ssh_key_name              = var.ssh_key_name
  tags                      = var.tags
}

