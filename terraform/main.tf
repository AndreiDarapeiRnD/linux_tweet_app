terraform {
  required_providers {
    qovery = {
      source = "qovery/qovery"
    }
  }
}

provider "qovery" {
  token = var.qovery_access_token
}

resource "qovery_aws_credentials" "aws_creds" {
  organization_id   = var.qovery_organization_id
  name              = "AWS Creds1"
  access_key_id     = var.aws_access_key_id
  secret_access_key = var.aws_secret_access_key
}

resource "qovery_cluster" "tweet_cluster" {
  organization_id   = var.qovery_organization_id
  credentials_id    = qovery_aws_credentials.aws_creds.id
  name              = "Tweet cluster"
  description       = "Terraform demo cluster"
  cloud_provider    = "AWS"
  region            = "us-east-1"
  instance_type     = "T3A_MEDIUM"
  min_running_nodes = 3
  max_running_nodes = 4
  state             = "RUNNING"

  depends_on = [
    qovery_aws_credentials.aws_creds
  ]
}

resource "qovery_project" "tweet_project" {
  organization_id = var.qovery_organization_id
  name            = "Tweet App"

  depends_on = [
    qovery_cluster.tweet_cluster
  ]
}

resource "qovery_environment" "production" {
  project_id = qovery_project.tweet_project.id
  name       = "production"
  mode       = "PRODUCTION"
  cluster_id = qovery_cluster.tweet_cluster.id

  depends_on = [
    qovery_project.tweet_project
  ]
}

resource "qovery_application" "tweet_app" {
  environment_id = qovery_environment.production.id
  name           = "tweet_app"
  cpu            = 1000
  memory         = 256
  state          = "RUNNING"
  git_repository = {
    url       = "https://github.com/AndreiDarapeiRnD/linux_tweet_app.git"
    branch    = "master"
    root_path = "/"
  }
  build_mode            = "DOCKER"
  dockerfile_path       = "Dockerfile"
  min_running_instances = 1
  max_running_instances = 2
  ports                 = [
    {
      internal_port       = 80
      external_port       = 443
      protocol            = "HTTP"
      publicly_accessible = true
    }
  ]

  depends_on = [
    qovery_environment.production,
  ]
}