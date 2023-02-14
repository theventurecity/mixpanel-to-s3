data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" this {
  cluster_name = "redshift-manually-created"
}

data "aws_vpc" "this" {
  tags = {
    Name = "sandbox-1-dev"
  }
}

data "aws_subnet_ids" "private" {
  tags   = {
    type = "private"
  }
  vpc_id = data.aws_vpc.this.id
}
