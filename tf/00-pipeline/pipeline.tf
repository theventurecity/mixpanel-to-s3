resource "aws_codepipeline" "this" {
  name     = local.basename
  role_arn = aws_iam_role.codepipeline_role.arn
  tags     = local.default_tags

  artifact_store {
    location = aws_s3_bucket.pipeline.bucket
    type     = "S3"

    encryption_key {
      id   = data.aws_kms_alias.s3_default.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    /*action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket             = "${local.basename}-pipeline-${data.aws_caller_identity.current.account_id}-${var.region}"
        S3ObjectKey          = "${var.service}.zip"
        PollForSourceChanges = true
      }
    }*/
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      # Grant Access manually via Console
      configuration    = {
        ConnectionArn        = data.aws_ssm_parameter.codestar_arn.value
        FullRepositoryId     = "appinioGmbH/appi-${var.service}"
        BranchName           = var.branch[var.env]
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "DeployInfrastructure"

    dynamic "action" {
      for_each = var.env == "prod" ? [1] : []
      content {
        name      = "Approval"
        category  = "Approval"
        owner     = "AWS"
        provider  = "Manual"
        version   = "1"
        run_order = 1
        configuration = {
          NotificationArn = aws_sns_topic.codepipeline_manual_approval[0].arn
        }
      }
    }

    action {
      name            = "ECR"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = [
        "source_output"
      ]
      version         = "1"
      run_order       = 2

      configuration = {
        ProjectName = module.codebuild_deploy_ecr.name
      }
    }
  }

  stage {
    name = "Build"

      action {
        name            = "Project"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = [
          "source_output"
        ]
        version         = "1"
        run_order       = 3

        configuration = {
          ProjectName = module.codebuild_build_image.name
        }
      }
  }

  stage {
    name = "DeployECS"

    action {
      name            = "ECS"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = [
        "source_output"
      ]
      version         = "1"
      run_order       = 4

      configuration = {
        ProjectName = module.codebuild_deploy_ecs.name
      }
    }
  }
}


resource "aws_sns_topic" "codepipeline_manual_approval" {
  count = var.env == "prod" ? 1 : 0
  name = "${local.basename}-pipeline-manual-approval"
}

resource "aws_sns_topic_subscription" "codepipeline_manual_approval" {
  count = var.env == "prod" ? 1 : 0
  topic_arn = aws_sns_topic.codepipeline_manual_approval[0].arn
  protocol  = "lambda"
  endpoint  = data.aws_lambda_function.code_pipeline_slack_notification[0].arn
}

resource "aws_lambda_permission" "allow_sns" {
  count = var.env == "prod" ? 1 : 0
  statement_id  = "AllowExecutionFromSns-${var.service}"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.code_pipeline_slack_notification[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.codepipeline_manual_approval[0].arn
}