#------------------------------------------------------------------------------------------------------------------
# Lambda function
#------------------------------------------------------------------------------------------------------------------

data "archive_file" "cleanup_scheduler" {
  type               = "zip"
  source_file        = "${path.module}/${local.lambda_file}_lambda/${local.lambda_file}.py"
  output_path        = "${path.module}/files/${local.lambda_file}.zip"
}

resource "aws_lambda_function" "ebs-vols-cleanup-scheduler" {
  filename         = data.archive_file.cleanup_scheduler.output_path
  function_name    = local.lambda_name
  role             = aws_iam_role.cleanup_scheduler.arn
  handler          = "${local.lambda_file}.handler"
  source_code_hash = filebase64sha256(data.archive_file.cleanup_scheduler.output_path)
  runtime          = "python3.8"
  timeout          = 300 
  
  environment {
    variables = {
      DAYS_LIMIT               = var.solr_cache_vols_days_limit
    }
  }
}

#------------------------------------------------------------------------------------------------------------------
# Event Rules
#------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "cleanup_scheduler_event_rule" {
  name                = "${local.application_name}-cleanup-scheduler-event-rule"
  description         = "Rule to run alfresco SOLR search EBS volumes cleanup scheduler daily"
  schedule_expression = var.cleanup_scheduler_expression
  is_enabled          = var.enable_cleanup_scheduler
}

#------------------------------------------------------------------------------------------------------------------
# Event Rule Targets
#------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_target" "cleanup_scheduler_event_target" {
  arn      = aws_lambda_function.ebs-vols-cleanup-scheduler.arn
  rule     = aws_cloudwatch_event_rule.cleanup_scheduler_event_rule.name
  target_id = aws_lambda_function.ebs-vols-cleanup-scheduler.id
}

#------------------------------------------------------------------------------------------------------------------
# Lambda Permissions
#------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "allow_cloudwatch_cleanup_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs-vols-cleanup-scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cleanup_scheduler_event_rule.arn
}
