resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  name = "mixpanel"
}

resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.aws_glue_catalog_database.name
  schedule      = "cron(0 8 * * ? *)"
  name          = "mixpanel-crawler"
  role          = aws_iam_role.glue.arn
    table_prefix = "stg_"
  s3_target {
    path = "s3://${aws_s3_bucket.appi_redshift_mixpanel_bucket.bucket}/mixpanel/"
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

// use "aws_iam_role_policy_attachment" over "aws_iam_policy_attachment" for the following reason
// https://github.com/hashicorp/terraform-provider-aws/issues/3555
resource "aws_iam_role_policy_attachment" "s3_glue" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "service_glue" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_console" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_readonly_console" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
