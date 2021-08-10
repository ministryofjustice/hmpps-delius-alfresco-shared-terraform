resource "aws_ecs_task_definition" "task_def" {
  family                   = format("%s-task-definition", var.ecs_config["name"])
  container_definitions    = var.container_definitions
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-task-definition", var.ecs_config["name"])
    }
  )
}
