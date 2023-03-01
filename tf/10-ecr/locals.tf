locals {
  basename = "${var.app}-${var.service}-${var.env}"

  default_tags = {
    app = var.app
    service = var.service
    env = var.env
    crew = var.crew
    // Vanta related tags
    VantaOwner = var.vanta_owner
    VantaNonProd = var.env == "prod" ? false : true
  }
}
