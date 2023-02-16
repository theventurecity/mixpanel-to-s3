resource "aws_scheduler_schedule" "mixPanel" {
  name = "triggerMixpanel"
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron( 0 6 * * ? *)"

  target {
    arn      = data.aws_ecs_cluster.this.arn
    role_arn = aws_iam_role.scheduler.arn
    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.this.arn
      launch_type         = "FARGATE"
      network_configuration {
        subnets         = data.aws_subnet_ids.private.ids
      }
    }

  }
}


resource "aws_iam_role" "scheduler" {
  name = "${local.basename}-scheduler"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
{
            "Effect": "Allow",
            "Principal": {
                "Service": "scheduler.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
  ]
}
EOF
}



resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${local.basename}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "scheduler:*",
                "ecs:RunTask",
                "iam:PassRole"

            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}