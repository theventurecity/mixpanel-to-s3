resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = 365
  tags              = var.default_tags
}

resource "aws_codebuild_project" "this" {
  depends_on = [aws_cloudwatch_log_group.codebuild]

  name          = var.project_name
  build_timeout = var.build_timeout
  service_role  = var.role_arn
  tags          = var.default_tags

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    compute_type                = var.container_type
    image                       = var.image
    privileged_mode             = var.privileged_mode
    environment_variable {
      name  = "TARGET_DIRECTORY"
      value = var.target_directory
    }
    environment_variable {
      name  = "ENV"
      value = var.env
    }

  }
}
