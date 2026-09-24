output "aws_region" {
  value = var.aws_region
}
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "ecr_repository_urls" {
  value = {
    for name, repository in aws_ecr_repository.services :
    name => repository.repository_url
  }
}
output "auth_db_endpoint" {
  value = aws_db_instance.auth.address
}

output "auth_db_port" {
  value = aws_db_instance.auth.port
}

output "auth_db_name" {
  value = aws_db_instance.auth.db_name
}

output "flag_db_endpoint" {
  value = aws_db_instance.flag.address
}

output "flag_db_port" {
  value = aws_db_instance.flag.port
}

output "flag_db_name" {
  value = aws_db_instance.flag.db_name
}

output "targeting_db_endpoint" {
  value = aws_db_instance.targeting.address
}

output "targeting_db_port" {
  value = aws_db_instance.targeting.port
}

output "targeting_db_name" {
  value = aws_db_instance.targeting.db_name
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  value = aws_elasticache_replication_group.redis.port
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.analytics.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.togglemaster.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.togglemaster.arn
}
