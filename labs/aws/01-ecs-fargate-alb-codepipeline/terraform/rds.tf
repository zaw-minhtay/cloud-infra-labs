# Aurora MySQL cluster in the private DB subnets: writer in AZ a, reader (failover target) in AZ c.

resource "aws_db_subnet_group" "main" {
  name       = local.rds.subnet_group_name
  subnet_ids = local.subnet_ids.db
}

resource "aws_rds_cluster" "main" {
  cluster_identifier          = local.rds.cluster_identifier
  engine                      = local.rds.engine
  database_name               = local.rds.database_name
  master_username             = local.rds.master_username
  manage_master_user_password = true # RDS generates the password and stores it in Secrets Manager

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main["db"].id]
  storage_encrypted      = true

  backup_retention_period   = local.rds.backup_retention_days
  copy_tags_to_snapshot     = true
  deletion_protection       = local.rds.deletion_protection
  skip_final_snapshot       = local.rds.skip_final_snapshot
  final_snapshot_identifier = local.rds.skip_final_snapshot ? null : local.rds.final_snapshot_identifier
}

resource "aws_rds_cluster_instance" "writer" {
  identifier           = local.rds.writer.identifier
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = local.rds.instance_class
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  availability_zone    = local.rds.writer.az
  db_subnet_group_name = aws_db_subnet_group.main.name
  promotion_tier       = local.rds.writer.promotion_tier
  publicly_accessible  = false
}

# Created after the writer, so the first instance (the writer) is always in the first AZ.
resource "aws_rds_cluster_instance" "reader" {
  identifier           = local.rds.reader.identifier
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = local.rds.instance_class
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  availability_zone    = local.rds.reader.az
  db_subnet_group_name = aws_db_subnet_group.main.name
  promotion_tier       = local.rds.reader.promotion_tier
  publicly_accessible  = false

  depends_on = [aws_rds_cluster_instance.writer]
}
