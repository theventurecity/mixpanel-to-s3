resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = "mixpanel"
}

resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  schedule      = "cron( 0 8 * * ? *)"
  name          = "mixpanel-crawler"
  role          = aws_iam_role.glue.arn
    table_prefix = "stg_"
  s3_target {
    path = "s3://${aws_s3_bucket.appi_mixpanel_bucket.bucket}/mixpanel/year=2023/"
  }
}

resource "aws_iam_role" "glue" {
  name = "GlueS3RoleMixpanel"
  tags = local.default_tags

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "glue.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_glue" {
  name       = "S3ForGlue"
  roles      = [aws_iam_role.glue.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy_attachment" "service_glue" {
  name       = "GlueServiceRole"
  roles      = [aws_iam_role.glue.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_policy_attachment" "console_glue" {
  name       = "GlueConsole"
  roles      = [aws_iam_role.glue.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

resource "random_string" "redshift_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "redshift_password" {
  name      = "redshift_cluster"
  type      = "SecureString"
  value     = random_string.redshift_password.result
  overwrite = "false"
  lifecycle {
    ignore_changes = [
      value,
      overwrite,
    ]
  }
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "tf-redshift-cluster"
  database_name      = aws_glue_catalog_database.aws_glue_catalog_database.name
  master_username    = "admin"
  master_password    = aws_ssm_parameter.redshift_password.value
  node_type          = "dc2.large"
  cluster_type       = "single-node"
}