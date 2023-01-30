resource "aws_codestarnotifications_notification_rule" "this" {
  name     = "${local.basename}-pipeline-notifications"
  resource = aws_codepipeline.this.arn

  detail_type    = "BASIC"
  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-superseded",
    "codepipeline-pipeline-manual-approval-needed",
    "codepipeline-pipeline-manual-approval-failed",
    "codepipeline-pipeline-manual-approval-succeeded"
  ]

  target {
    address = data.aws_sns_topic.account_wide_alarming.arn
  }
}