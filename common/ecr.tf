locals {
  alfresco_docker_images = ["hmpps/alfresco-content", "hmpps/alfresco-share"]
  ecr_repos              = var.environment_name == "alfresco-dev" ? local.alfresco_docker_images : []
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.ecr_repos)
  name                 = each.key
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  tags = local.tags
}
