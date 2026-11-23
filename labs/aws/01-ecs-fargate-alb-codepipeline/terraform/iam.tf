# IAM roles. The policies are JSON files in policy/iam/:
#   trust_policy.json                which AWS service can use each role
#   <role>_policy.json               what each role may do (limited to this lab's resources)

resource "aws_iam_role" "main" {
  for_each = local.iam.roles

  name = each.value.name
  assume_role_policy = templatefile("${local.iam.policy_dir}/trust_policy.json", {
    service = each.value.service
  })
}

# Image pull and logs for the ECS task execution role come from AWS's managed policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.main["ecs_task_execution"].name
  policy_arn = local.iam.ecs_task_execution_managed_policy
}

resource "aws_iam_role_policy" "main" {
  for_each = local.iam_inline_policies

  name   = each.value.name
  role   = aws_iam_role.main[each.key].id
  policy = each.value.document
}
