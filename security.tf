resource "aws_security_group_rule" "app-to-datastore" {
  security_group_id        = local.security_group_id
  type                     = "egress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = local.db_security_group_id
}

resource "aws_security_group_rule" "datastore-from-app" {
  security_group_id        = local.db_security_group_id
  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = local.security_group_id
}
