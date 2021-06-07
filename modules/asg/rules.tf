locals {
  target_group_list    = [aws_lb_target_group.environment.arn]
  listener_arn_list    = [module.https_listener.listener_arn]
  https_listener_rules = var.https_listener_rules
}

module "alfresco_listener" {
  source               = "../loadbalancer/alb/create_listener_rule"
  listener_arn_list    = local.listener_arn_list
  https_listener_rules = local.https_listener_rules
  target_group_list    = local.target_group_list
}
