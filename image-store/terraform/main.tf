provider "aws" {
  region = var.aws_region
}

module "s3_cloudfront_module" {
  source            = "./modules/s3-cloudfront"
  bucket_name       = var.bucket_name
  bucket_acl        = var.bucket_acl
  directory_path    = var.directory_path
  enable_versioning = var.enable_versioning
  cloudfront_settings = var.cloudfront_settings
}
# ECS Cluster Module
module "ecs_cluster" {
  source = "./modules/ecs-setup"   
  my_proj_clus_name = var.my_proj_clus_name
  image_id = var.image_id
  instance_type = var.instance_type
  security_groups = var.security_groups
  ecs_auto_scale = var.ecs_auto_scale
}

