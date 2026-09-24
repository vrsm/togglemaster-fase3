resource "aws_db_subnet_group" "main" {
  name = "togglemaster-rds-subnet-group"

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "togglemaster-rds-subnet-group"
  }
}
resource "aws_db_instance" "auth" {
  identifier = "togglemaster-auth-db"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 30
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "auth_db"
  username = "togglemaster"
  password = random_password.auth_db.result

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0

  apply_immediately   = true
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name    = "togglemaster-auth-db"
    Service = "auth-service"
  }
}

resource "aws_db_instance" "flag" {
  identifier = "togglemaster-flag-db"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 30
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "flags_db"
  username = "togglemaster"
  password = random_password.flag_db.result

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0

  apply_immediately   = true
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name    = "togglemaster-flag-db"
    Service = "flag-service"
  }
}

resource "aws_db_instance" "targeting" {
  identifier = "togglemaster-targeting-db"

  engine         = "postgres"
  engine_version = "16"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 30
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "targeting_db"
  username = "togglemaster"
  password = random_password.targeting_db.result

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0

  apply_immediately   = true
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name    = "togglemaster-targeting-db"
    Service = "targeting-service"
  }
}
