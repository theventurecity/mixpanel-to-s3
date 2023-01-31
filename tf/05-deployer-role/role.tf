data "aws_kms_alias" "s3_default_key" {
  name = "alias/aws/s3"
}

data "aws_kms_key" "s3_default_key" {
  key_id = data.aws_kms_alias.s3_default_key.target_key_id
}

resource "aws_iam_role" "deployer" {
  name = "${local.basename}-deployer"
  tags = local.default_tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.basename}-codebuild"
      }
    },
    
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*admin*",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*developer*",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*Administrator*"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "readonly_ec2" {
  name       = "ReadOnlyEC2"
  roles      = [aws_iam_role.deployer.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_policy_attachment" "readonly_ecr" {
  name       = "ReadOnlyECR"
  roles      = [aws_iam_role.deployer.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "deployer" {
  name = "${local.basename}-deployer"
  role = aws_iam_role.deployer.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid":"S3TerraformStateLock",
      "Effect":"Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-${data.aws_caller_identity.current.account_id}-${var.region}",
        "arn:aws:s3:::terraform-state-${data.aws_caller_identity.current.account_id}-${var.region}/*"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::appi-redshift-mixpanel-${var.env}"
      ]
    },
    {
      "Sid":"KMSTerraformStateLock",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        "${data.aws_kms_key.s3_default_key.arn}"
      ]
    },
    {
      "Sid":"DynamoTerraformStateLock",
      "Effect":"Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/terraform-state-lock"
    },
    {
      "Effect":"Allow",
      "Action": [
        "iam:AttachRolePolicy",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfilesForRole",
        "iam:PutRolePolicy",
        "iam:CreateServiceLinkedRole",
        "iam:ListRolePolicies"
      ],
      "Resource": [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app}-${var.env}-*",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app}-${var.service}-${var.env}-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "iam:CreateServiceLinkedRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy"
      ],
      "Resource": [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/*"
      ]
    },
   
    {
      "Sid": "ECR",
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": [
        "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${local.basename}"
      ]
    },
    {
      "Sid": "ECSread",
      "Effect": "Allow",
      "Action": [
        "ecs:Describe*",
        "ecs:List*"
      ],
      "Resource": ["*"]
    },
    {
      "Sid": "ECSwrite",
      "Effect": "Allow",
      "Action": [
        "ecs:*"
      ],
      "Resource": [
        "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${var.app}-${var.env}/${local.basename}",
        "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task/${var.app}-${var.env}/*",
        "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/*"
      ]
    },
   
    {
      "Sid": "CWLogswrite",
      "Effect": "Allow",
      "Action": [
        "logs:*"
      ],
      "Resource": [
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.basename}",
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.basename}:log-stream:*"

      ]
    },
    {
      "Sid": "Generic",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "ecs:RegisterTaskDefinition",
        "ecs:DeregisterTaskDefinition",
        "iam:*",
        
        "scheduler:*",
        "cloudwatch:*",
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}