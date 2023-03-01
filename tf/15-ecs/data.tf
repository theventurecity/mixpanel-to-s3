data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" this {
  cluster_name = "${var.app}-${var.env}"
}

data "aws_vpc" "this" {
  tags = {
    Name = "${var.app}-${var.env}"
  }
}

data "aws_subnet_ids" "private" {
  tags   = {
    type = "private"
  }
  vpc_id = data.aws_vpc.this.id
}
