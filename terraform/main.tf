# Automatically fetch latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

locals {
  project_slug = replace(lower(var.project_name), " ", "-")
}

# -------------------------
# VPC
# -------------------------
module "vpc" {
  source              = "./modules/vpc"
  project_slug        = local.project_slug
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs= var.private_subnet_cidrs
  tags                = var.tags
}

# -------------------------
# Bastion
# -------------------------
module "bastion" {
  source            = "./modules/bastion"
  project_slug      = local.project_slug
  vpc_id            = module.vpc.vpc_id
  public_subnets    = module.vpc.public_subnet_ids
  key_name          = var.key_name
  allowed_ssh_cidr  = var.allowed_ssh_cidr
  ami_id            = data.aws_ami.ubuntu.id
  tags              = var.tags
}

# -------------------------
# Prometheus Primary + Standby
# -------------------------
module "prometheus_ec2" {
  source             = "./modules/prometheus_ec2"
  project_slug       = local.project_slug
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnet_ids
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  key_name           = var.key_name
  tags               = var.tags
}

# -------------------------
# S3 Backup Bucket
# -------------------------
module "s3_backup" {
  source        = "./modules/s3"
  create_bucket = var.enable_backup_bucket
  project_slug  = local.project_slug
  tags          = var.tags
}
#
## -------------------------
## IAM Roles
## -------------------------
#module "iam" {
#  source       = "./modules/iam"
#  project_slug = local.project_slug
#  tags         = var.tags
#}
#
## -------------------------
## Lambda for Failover
## -------------------------
##module "lambda_failover" {
##  source               = "./modules/lambda_failover"
##  project_slug         = local.project_slug
#  primary_ip           = module.prometheus_ec2.primary_private_ip
#  standby_ip           = module.prometheus_ec2.standby_private_ip
#  lambda_role_arn      = module.iam.lambda_role_arn
#  vpc_id               = module.vpc.vpc_id
#  private_subnets      = module.vpc.private_subnet_ids
#
#  # NEW - required for failover
#  zone_id              = module.route53_private_dns.private_zone_id
#  record_name          = module.route53_private_dns.prometheus_record_fqdn
#
#  tags                 = var.tags
#}
# -------------------------
# (Optional) Jenkins
# -------------------------

# -------------------------
# OUTPUTS (Restored)
# -------------------------

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "primary_private_ip" {
  value = module.prometheus_ec2.primary_private_ip
}

output "standby_private_ip" {
  value = module.prometheus_ec2.standby_private_ip
}

output "backup_bucket_name" {
  value = module.s3_backup.backup_bucket_name
}

#output "lambda_name" {
#  value = module.lambda_failover.lambda_name
#}

# -------------------------
# Private DNS for HA Failover
# -------------------------
module "route53_private_dns" {
  source             = "./modules/route53_private_dns"
  project_slug       = local.project_slug
  vpc_id             = module.vpc.vpc_id
  primary_private_ip = module.prometheus_ec2.primary_private_ip
  standby_private_ip = module.prometheus_ec2.standby_private_ip
}



# -------------------------
## API Gateway for Alertmanager -> Lambda failover
## -------------------------
##module "api_gateway_failover" {
##  source       = "./modules/api_gateway_failover"
##  project_slug = local.project_slug
##  lambda_name  = module.lambda_failover.lambda_name
#  tags         = var.tags
#}

#output "api_gateway_endpoint" {
##  value = module.api_gateway_failover.api_endpoint
##}
