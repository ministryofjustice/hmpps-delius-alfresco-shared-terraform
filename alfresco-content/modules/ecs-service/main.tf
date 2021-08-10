locals {
  secrets_format = "arn:aws:ssm:${var.ecs_config["region"]}:${var.ecs_config["account_id"]}:parameter%s"
}
