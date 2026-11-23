# Log groups (app and build) and CloudWatch alarms. Alarms have no notification target yet
# (sending them to SNS is listed under "What I'd improve next").

resource "aws_cloudwatch_log_group" "main" {
  for_each = local.log_groups

  name              = each.value.name
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_metric_alarm" "main" {
  for_each = local.alarms

  alarm_name          = "${local.name_prefix}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = each.value.dimensions
}
