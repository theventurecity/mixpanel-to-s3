locals {
  basename     = "${var.app}-${var.service}-${var.env}"

  default_tags = {
    app          = var.app
    env          = var.env
    service      = var.service
    crew         = var.crew
  }
}
