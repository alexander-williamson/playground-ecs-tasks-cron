# tell terraform which provider plugins are needed
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }
}

# configure aws provider
provider "aws" {
  default_tags {
    tags = {
      "stack" = "playground-ecs-tasks-cron"
      "canBeDeleted" = "true" 
    }
  }
}