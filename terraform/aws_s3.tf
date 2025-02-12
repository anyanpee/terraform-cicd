resource "aws_s3_bucket" "bucket" {
  bucket        = var.project_prefix
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "portfolio" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "permissions" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "svg"  = "image/svg+xml"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
  }
}


resource "aws_s3_object" "upload_object" {
  for_each = fileset("../portfolio/", "**")
  bucket   = aws_s3_bucket.bucket.id
  key      = each.value
  etag     = filemd5("../portfolio/${each.value}")
  source   = "../portfolio/${each.value}"
  content_type = lookup(
    local.mime_types,
    split(".", each.value)[1],
    ""
  )
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"
        ]
      }
    ]
  })
}


output "s3_website_endpoint" {
  value = aws_s3_bucket.bucket.website_endpoint
}
