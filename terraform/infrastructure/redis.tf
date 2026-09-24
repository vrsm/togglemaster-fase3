resource "aws_elasticache_subnet_group" "redis" {
  name = "togglemaster-redis-subnet-group"

  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "togglemaster-redis"
  description          = "Redis do evaluation-service"

  engine = "redis"

  node_type          = "cache.t3.micro"
  num_cache_clusters = 1

  port = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  automatic_failover_enabled = false
  multi_az_enabled           = false

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  apply_immediately = true

  tags = {
    Name    = "togglemaster-redis"
    Service = "evaluation-service"
  }
}
