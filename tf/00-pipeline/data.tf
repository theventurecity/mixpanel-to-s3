data "aws_kms_alias" "s3_default" {
  name = "alias/aws/s3"
}

data "aws_vpc" "pipeline" {
  tags = {
    Name = "${var.app}-${var.env}"
  }
}

data "aws_subnet_ids" "pipeline_private" {
  vpc_id = data.aws_vpc.pipeline.id

  tags = {
    type = "private"
  }
}

data "aws_caller_identity" "current" {}

data "aws_sns_topic" "account_wide_alarming" {
  name = "account-wide-alarming"
}

data "aws_ssm_parameter" "codestar_arn" {
  name = "codestar_arn"
}

data "aws_lambda_function" "code_pipeline_slack_notification" {
  count = var.env == "prod" ? 1 : 0
  function_name = "lambda-${var.env}-slack_notification_codepipeline"
}