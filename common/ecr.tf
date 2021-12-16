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

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::895523100917:role/hmpps-eng-builds",
        format("arn:aws:iam::%s:root", local.account_id)
      ]
    }
  }
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  for_each   = toset(local.ecr_repos)
  repository = each.key
  policy     = data.aws_iam_policy_document.ecr_policy.json
  depends_on = [
    aws_ecr_repository.repos
  ]
}
