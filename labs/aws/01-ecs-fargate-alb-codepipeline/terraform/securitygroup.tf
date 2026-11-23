# Security groups (one per tier) and their rules. The rules are listed in securitygroup_local.tf.
# Ingress and egress rules are separate AWS resource types, so they need one block each.

resource "aws_security_group" "main" {
  for_each = local.security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.main.id

  tags = { Name = each.value.name }
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each = { for key, rule in local.security_group_rules : key => rule if rule.direction == "ingress" }

  security_group_id = aws_security_group.main[each.value.sg].id
  description       = each.value.description
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port

  cidr_ipv4                    = each.value.cidr
  referenced_security_group_id = each.value.peer_sg == null ? null : aws_security_group.main[each.value.peer_sg].id
  prefix_list_id               = each.value.s3_endpoint ? aws_vpc_endpoint.main["s3"].prefix_list_id : null
}

resource "aws_vpc_security_group_egress_rule" "main" {
  for_each = { for key, rule in local.security_group_rules : key => rule if rule.direction == "egress" }

  security_group_id = aws_security_group.main[each.value.sg].id
  description       = each.value.description
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port

  cidr_ipv4                    = each.value.cidr
  referenced_security_group_id = each.value.peer_sg == null ? null : aws_security_group.main[each.value.peer_sg].id
  prefix_list_id               = each.value.s3_endpoint ? aws_vpc_endpoint.main["s3"].prefix_list_id : null
}
