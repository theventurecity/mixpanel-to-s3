locals {
  basename = "${var.app}-${var.service}-${var.env}"

  default_tags = {
    app = var.app
    service = var.service
    env = var.env
    crew = var.crew
  }

  container_port_https = 443
  container_port_http = 80
  container_port_custom_port = 9090

  root_domain = "appinio.com"

  image_version = "latest"
  image_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.basename}"

  desired_count = {
    dev = 0
    stage = 1
    prod = 10
  }

  container_memory = {
    dev = 2048
    stage = 2048
    prod = 4096
  }

  container_cpu = {
    dev = 1024
    stage = 1024
    prod = 2048
  }
}
