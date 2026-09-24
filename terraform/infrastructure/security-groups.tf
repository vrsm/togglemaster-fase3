resource "aws_security_group" "rds" {
  name        = "togglemaster-rds-sg"
  description = "Security group dos bancos PostgreSQL do ToggleMaster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL dentro da VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Saida para a VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "togglemaster-rds-sg"
  }
}

resource "aws_security_group" "redis" {
  name        = "togglemaster-redis-sg"
  description = "Security group do Redis do ToggleMaster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Redis dentro da VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Saida para a VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "togglemaster-redis-sg"
  }
}
