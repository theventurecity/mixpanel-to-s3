module "codebuild_deploy_ecr" {
  source              = "../modules/codebuild"

  project_name        = "${var.app}-${var.service}-deploy-ecr-${var.env}"
  role_arn            = aws_iam_role.codebuild_role.arn
  buildspec           = "tf/00-pipeline/buildspecs/deploy-infrastructure.yaml"
  target_directory    = "tf/10-ecr"
  env                 = var.env
  vpc_id              = data.aws_vpc.pipeline.id
  subnet_ids          = data.aws_subnet_ids.pipeline_private.ids
  security_group_id   = aws_security_group.codebuild_pipeline.id

  default_tags        = local.default_tags
}

module "codebuild_build_image" {
  source              = "../modules/codebuild-project"

  project_name        = "${var.app}-${var.service}-build-image-${var.env}"
  role_arn            = aws_iam_role.codebuild_role.arn
  buildspec           = "tf/00-pipeline/buildspecs/buildspec.yaml"
  app                 = var.app
  service             = var.service
  region              = var.region
  account_id          = data.aws_caller_identity.current.account_id
  env                 = var.env
  vpc_id              = data.aws_vpc.pipeline.id
  subnet_ids          = data.aws_subnet_ids.pipeline_private.ids
  security_group_id   = aws_security_group.codebuild_pipeline.id
  privileged_mode     = true

  default_tags        = local.default_tags
}

module "codebuild_deploy_ecs" {
  source              = "../modules/codebuild"

  project_name        = "${var.app}-${var.service}-deploy-ecs-${var.env}"
  role_arn            = aws_iam_role.codebuild_role.arn
  buildspec           = "tf/00-pipeline/buildspecs/deploy-infrastructure.yaml"
  target_directory    = "tf/15-ecs"
  env                 = var.env
  vpc_id              = data.aws_vpc.pipeline.id
  subnet_ids          = data.aws_subnet_ids.pipeline_private.ids
  security_group_id   = aws_security_group.codebuild_pipeline.id

  default_tags        = local.default_tags
}
