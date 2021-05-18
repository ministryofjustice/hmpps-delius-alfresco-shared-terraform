resource "aws_lb_listener_rule" "environment" {
  listener_arn = element(var.listener_arn_list, lookup(var.https_listener_rules[count.index], "https_listener_index", count.index))
  count        = var.create_rules ? length(var.https_listener_rules) : 0
  priority     = lookup(var.https_listener_rules[count.index], "priority", null)

  # forward actions
  dynamic "action" {
    for_each = [
      for action_rule in var.https_listener_rules[count.index].actions :
      action_rule
      if action_rule.type == "forward"
    ]

    content {
      type             = action.value["type"]
      target_group_arn = element(var.target_group_list, lookup(action.value, "target_group_index", count.index))
    }
  }

  # Path Pattern condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "path_patterns", [])) > 0
    ]

    content {
      path_pattern {
        values = condition.value["path_patterns"]
      }
    }
  }

  # Source IP address condition
  dynamic "condition" {
    for_each = [
      for condition_rule in var.https_listener_rules[count.index].conditions :
      condition_rule
      if length(lookup(condition_rule, "source_ips", [])) > 0
    ]

    content {
      source_ip {
        values = condition.value["source_ips"]
      }
    }
  }
}


# resource "aws_lb_listener_rule" "environment" {
#   listener_arn = var.listener_arn
#   count        = var.create_rules ? length(var.https_listener_rules) : 0
#   priority     = lookup(var.https_listener_rules[count.index], "priority", null)

#   # Path Pattern condition
#   dynamic "condition" {
#     for_each = [
#       for condition_rule in var.https_listener_rules[count.index].conditions :
#       condition_rule
#       if length(lookup(condition_rule, "path_patterns", [])) > 0
#     ]

#     content {
#       path_pattern {
#         values = condition.value["path_patterns"]
#       }
#     }
#   }

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.environment.arn
#   }
# }
