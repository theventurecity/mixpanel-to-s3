resource "aws_iam_role" "codepipeline_role" {
  name = "${local.basename}-codepipeline"
  tags = local.default_tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.basename}-codepipeline"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:Get*",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.pipeline.arn}",
        "${aws_s3_bucket.pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        "${data.aws_kms_alias.s3_default.target_key_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "codestar-connections:UseConnection"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy_sns_prod" {
  count = var.env == "prod" ? 1 : 0
  name = "${local.basename}-codepipeline-prod-sns-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": [
        "${aws_sns_topic.codepipeline_manual_approval[0].arn}"
      ]
    }
    
    
  ]
}
EOF
}

resource "aws_iam_role" "codebuild_role" {
  name = "${local.basename}-codebuild"
  tags = local.default_tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${local.basename}-codebuild"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.basename}-deployer",
        "arn:aws:iam::${var.account_ids.dns}:role/dns-deployer"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:DeleteObject",
        "s3:GetBucketLocation",
        "s3:GetObjectAcl",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.pipeline.arn}",
        "${aws_s3_bucket.pipeline.arn}/*",
        "arn:aws:s3:::${local.basename}-${data.aws_caller_identity.current.account_id}-${var.region}",
        "arn:aws:s3:::${local.basename}-${data.aws_caller_identity.current.account_id}-${var.region}/*",
        "arn:aws:s3:::${var.app}-${var.env}-configfiles-${data.aws_caller_identity.current.account_id}-${var.region}",
        "arn:aws:s3:::${var.app}-${var.env}-configfiles-${data.aws_caller_identity.current.account_id}-${var.region}/*",
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Resource": [
        "${data.aws_ssm_parameter.codestar_arn.value}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        "${data.aws_kms_alias.s3_default.target_key_arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
        "ec2:DescribeVpcs",
        "ec2:DescribeDhcpOptions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": [
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.basename}-*",
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/npm_token"
      ]
    },
    {
      "Sid": "ECRPush",
      "Effect": "Allow",
      "Action": [
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
)
}
