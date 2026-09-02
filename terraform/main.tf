locals {
    config = yamldecode(file("env-config.yaml"))
}

provider "aws" {
    region = local.config.region
    default_tags {
        tags = {
            project = local.config.project
        }
    }
}

module "backend" {
  source = "./modules/backend"
  config = local.config
}
