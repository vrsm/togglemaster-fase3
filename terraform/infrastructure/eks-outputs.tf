output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  value = aws_eks_cluster.main.version
}

output "eks_node_group_name" {
  value = aws_eks_node_group.main.node_group_name
}

output "eks_node_instance_type" {
  value = "t3.small"
}
