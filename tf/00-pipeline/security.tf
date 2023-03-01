resource "aws_security_group" "codebuild_pipeline" {
  name   = "${local.basename}-codebuild"
  vpc_id = data.aws_vpc.pipeline.id
  description = "Allow Egress from Codebuild Pipeline"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, {
    "Name": "${local.basename}-codebuild"
  })
}
