variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "my_proj_clus_name" {
  description = "Name of the ecs cluster"
  default = "mycluster"
}
variable "image_id" {
  description = "instance image id fro launch template"
  default = "ami-08a52ddb321b32a8c"
}
variable "instance_type" {
  description = "instance type launch template"
  default = "t3.small"
}
variable "security_groups" {
  description = "security group id for launch template"
  default = "sg-07792601ae4bb699c"
}
variable "create_before_destroy_lifecycle_policy_enabled" {
    description = "create_before_destroy life cycle policy true or false"
    type = bool
    default = true
  
}
variable "ecs_auto_scale" {
  description = "Configuration for ECS Auto Scaling Group"
  type = map(any)
 default = {
    max_size=4
    min_size=1
    vpc_zone_identifier="subnet-0e12e2bf768c7852e"
    desired_capacity= 1
    tag_key= "name"
    tag_value="test-ecs"
  }
}

variable "my-ecs-cap-provide-name" {
    default = "my-ecs-cap-provide"
    description = "my ecs capacity provide name"
  
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  default = "kkkk1111"
}

variable "bucket_acl" {
  description = "ACL for the S3 bucket"
  default     = "private"
}

variable "directory_path" {
  description = "Path to the directory containing the files"
  default = "/home/kavya/store-image-s3/client/build"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = false
}

variable "cloudfront_settings" {
  description = "CloudFront settings"
  type = map(object({
    enable_cloudfront        = bool
    comment                  = string
    allowed_methods          = list(string)
    cached_methods           = list(string)
    viewer_protocol_policy   = string
    min_ttl                  = number
    default_ttl              = number
    max_ttl                  = number
  }))
  default = {
    default_settings = {
      enable_cloudfront      = true
      comment                = "My CloudFront distribution"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
    }
  }
}

