resource "aws_s3_bucket" "appi_redshift_mixpanel_bucket" {
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
  bucket = aws_s3_bucket.appi_redshift_mixpanel_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "appi_redshift_mixpanel_bucket_block_public_access" {
  bucket                  = "appi-redshift-mixpanel-${var.env}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.appi_redshift_mixpanel_bucket]
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

resource "aws_s3_bucket_versioning" "appi_redshift_mongo_versioning" {
  bucket = aws_s3_bucket.appi_redshift_mongo_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "appi_redshift_mongo_bucket_block_public_access" {
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
resource "aws_s3_bucket" "appi_bi_bucket" {
  bucket = "appi-bi-${var.env}"
  tags = merge(local.default_tags, {
    VantaDescription      = "Bucket for BI stuff"
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
resource "aws_s3_bucket_public_access_block" "appi_bi_bucket_block_public_access" {
  bucket                  = "appi-bi-${var.env}"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.appi_bi_bucket]
}
resource "aws_s3_bucket_versioning" "appi_bi_bucket_versioning" {
  bucket = aws_s3_bucket.appi_bi_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_policy" "allow_access" {
  bucket = aws_s3_bucket.appi_bi_bucket.id
  policy = data.aws_iam_policy_document.allow_access.json
}
data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [
        "${var.account_ids.prod}",
        // todo: Get "Admin" & "Business-Intelligence" Group's roles by data
        "arn:aws:iam::943171019129:role/aws-reserved/sso.amazonaws.com/eu-central-1/AWSReservedSSO_admin_d77365dbcf93ae29",
        "arn:aws:iam::943171019129:role/aws-reserved/sso.amazonaws.com/eu-central-1/AWSReservedSSO_bi_0965ac42111dff99"
      ]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.appi_bi_bucket.arn,
      "${aws_s3_bucket.appi_bi_bucket.arn}/*"
    ]
  }
}