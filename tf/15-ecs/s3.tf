# resource "aws_s3_bucket" "appi_mixpanel_bucket" {
#   bucket = "appi-redshift-mixpanel-${var.env}"
#   tags = merge(local.default_tags, {
#     VantaDescription      = "bucket for uploaded media files"
#     VantaContainsUserData = var.env == "prod"
#   })
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
# }

# resource "aws_s3_bucket_versioning" "appi_mixpanel_bucket_versioning" {
#   bucket = aws_s3_bucket.appi_mixpanel_bucket.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
# resource "aws_s3_bucket_public_access_block" "appi_media_bucket_block_public_ccess" {
#   bucket                  = "appi-redshift-mixpanel-${var.env}"
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
#   depends_on              = [aws_s3_bucket.appi_mixpanel_bucket]
# }