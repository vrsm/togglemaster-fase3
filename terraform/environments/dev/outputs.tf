output "db_username" { value = var.db_username sensitive = true }
output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "vpc_id" { value = aws_vpc.this.id }
output "ecr_urls" { value = { for k,v in aws_ecr_repository.service : k => v.repository_url } }
output "rds_endpoints" { value = { for k,v in aws_db_instance.postgres : k => v.address } }
output "redis_endpoint" { value = aws_elasticache_replication_group.redis.primary_endpoint_address }
output "sqs_url" { value = aws_sqs_queue.togglemaster.url }
output "dynamodb_table" { value = aws_dynamodb_table.analytics.name }
