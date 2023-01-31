data "aws_ecr_image" "this" {
  repository_name = local.basename
  image_tag       = local.image_version
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.basename
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"
  cpu                      = local.container_cpu[var.env]
  memory                   = local.container_memory[var.env]
  requires_compatibilities = ["FARGATE"]
  tags                     = local.default_tags
  container_definitions    = <<EOF
[
  {
    "name": "${var.app}-${var.service}",
    "image": "${local.image_url}:${local.image_version}@${data.aws_ecr_image.this.image_digest}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${local.container_port_custom_port},
        "hostPort": ${local.container_port_custom_port},
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-region": "${var.region}",
            "awslogs-group": "${aws_cloudwatch_log_group.this.name}",
            "awslogs-stream-prefix": "ecs"
        }
    },
    "environment": [
      {
        "name": "S3_BUCKET",
        "value": "${aws_s3_bucket.appi_mixpanel_bucket.bucket}"
      },
      {
        "name": "S3_PATH",
        "value": "mixpanel"
      },
      {
        "name": "MIXPANEL_API_SECRET",
        "value": "4c0cd1e0f1a12fd937c60b7dc1245d3a"
      }
    ]
  }
]
EOF
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${local.basename}"
  retention_in_days = 365
  tags              = local.default_tags
}


