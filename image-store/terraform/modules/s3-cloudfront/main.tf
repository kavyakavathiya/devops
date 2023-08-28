variable "bucket_name" {
  description = "Name of the S3 bucket"
}

variable "bucket_acl" {
  description = "ACL for the S3 bucket"
  default     = "private"
}

variable "directory_path" {
  description = "Path to the directory containing the files"
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

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  acl    = var.bucket_acl

  versioning {
    enabled = var.enable_versioning
  }
}

resource "aws_s3_bucket_object" "my_bucket_objects" {
  bucket = aws_s3_bucket.my_bucket.id
  for_each = fileset(var.directory_path, "**")

  key      = each.key
  source   = "${var.directory_path}/${each.value}"

  content_type = "text/html"

  depends_on = [aws_s3_bucket.my_bucket]
}
resource "aws_cloudfront_distribution" "my_distribution" {
  for_each = var.cloudfront_settings

  enabled             = each.value.enable_cloudfront
  comment             = each.value.comment

  default_cache_behavior {
    allowed_methods  = each.value.allowed_methods
    cached_methods   = each.value.cached_methods
    viewer_protocol_policy = each.value.viewer_protocol_policy
    min_ttl                = each.value.min_ttl
    default_ttl            = each.value.default_ttl
    max_ttl                = each.value.max_ttl
    target_origin_id      = "S3-${aws_s3_bucket.my_bucket.id}"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code         = 404
    response_page_path = "/index.html"
    response_code      = 200
  }

  custom_error_response {
    error_code         = 403
    response_page_path = "/index.html"
    response_code      = 200
  }

  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.my_bucket.id}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_identity.cloudfront_access_identity_path
    }
  }
}


resource "aws_cloudfront_origin_access_identity" "my_identity" {
  comment = "My CloudFront Origin Access Identity"
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "MyBucketPolicy",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.my_identity.id}"
        },
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.my_bucket.id}/*",
      },
    ],
  })
}
