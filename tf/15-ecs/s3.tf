resource "aws_s3_bucket" "appi_mixpanel_bucket" {
  bucket = "appi-redshift-mixpanel-${var.env}"
  tags = merge(local.default_tags, {
    VantaDescription      = "bucket for mixpanel data"
    VantaContainsUserData = var.env == "prod"
  })
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_versioning" "appi_mixpanel_bucket_versioning" {
  bucket = aws_s3_bucket.appi_mixpanel_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "appi_media_bucket_block_public_ccess" {
  bucket                  = "appi-redshift-mixpanel-${var.env}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.appi_mixpanel_bucket]
}



resource "aws_s3_bucket" "appi_redshift_mongo_bucket" {
  bucket = "appi-redshift-mongo-${var.env}"
  tags = merge(local.default_tags, {
    VantaDescription      = "bucket for redshift mongo data"
    VantaContainsUserData = var.env == "prod"
  })
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_versioning" "appi_mixpanel_bucket_versioning" {
  bucket = aws_s3_bucket.appi_redshift_mongo_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "appi_mixpanel_bucket_block_public_ccess" {
  bucket                  = "appi-redshift-mongo-${var.env}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.appi_redshift_mongo_bucket]
}

resource "aws_iam_role" "s3_mongo_redshift" {
  name = "${local.basename}-appi-redshift-mongo"
  tags = local.default_tags

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "redshift.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "s3_mongo_redshift_policy" {
  name = "${local.basename}-appi-redshift-mongo"
  role = aws_iam_role.s3_mongo_redshift.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Sid": "AllowS3",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::appi-redshift-mongo-${var.env}/*",
                "arn:aws:s3:::appi-redshift-mongo-${var.env}"
            ]
        }
    
    
  ]
}
EOF
}