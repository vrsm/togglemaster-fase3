locals {
  name = var.project_name
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  services = toset(["auth-service", "flag-service", "targeting-service", "evaluation-service", "analytics-service"])
  cluster_role_arn = var.academy_mode ? data.aws_iam_role.lab[0].arn : aws_iam_role.eks_cluster[0].arn
  node_role_arn    = var.academy_mode ? data.aws_iam_role.lab[0].arn : aws_iam_role.eks_nodes[0].arn
}

# ---------------- Networking ----------------
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = { Name = "${local.name}-vpc" }
}
resource "aws_internet_gateway" "this" { vpc_id = aws_vpc.this.id tags = { Name = "${local.name}-igw" } }
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${local.name}-public-${count.index + 1}", "kubernetes.io/role/elb" = "1" }
}
resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = local.azs[count.index]
  tags = { Name = "${local.name}-private-${count.index + 1}", "kubernetes.io/role/internal-elb" = "1" }
}
resource "aws_route_table" "public" { vpc_id = aws_vpc.this.id route { cidr_block = "0.0.0.0/0" gateway_id = aws_internet_gateway.this.id } tags = { Name = "${local.name}-public-rt" } }
resource "aws_route_table_association" "public" { count = 2 subnet_id = aws_subnet.public[count.index].id route_table_id = aws_route_table.public.id }
resource "aws_eip" "nat" { domain = "vpc" }
resource "aws_nat_gateway" "this" { allocation_id = aws_eip.nat.id subnet_id = aws_subnet.public[0].id tags = { Name = "${local.name}-nat" } depends_on = [aws_internet_gateway.this] }
resource "aws_route_table" "private" { vpc_id = aws_vpc.this.id route { cidr_block = "0.0.0.0/0" nat_gateway_id = aws_nat_gateway.this.id } tags = { Name = "${local.name}-private-rt" } }
resource "aws_route_table_association" "private" { count = 2 subnet_id = aws_subnet.private[count.index].id route_table_id = aws_route_table.private.id }

# ---------------- IAM (personal account only) ----------------
resource "aws_iam_role" "eks_cluster" {
  count = var.academy_mode ? 0 : 1
  name = "${local.name}-eks-cluster-role"
  assume_role_policy = jsonencode({Version="2012-10-17",Statement=[{Effect="Allow",Principal={Service="eks.amazonaws.com"},Action="sts:AssumeRole"}]})
}
resource "aws_iam_role_policy_attachment" "eks_cluster" { count = var.academy_mode ? 0 : 1 role = aws_iam_role.eks_cluster[0].name policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" }
resource "aws_iam_role" "eks_nodes" {
  count = var.academy_mode ? 0 : 1
  name = "${local.name}-eks-node-role"
  assume_role_policy = jsonencode({Version="2012-10-17",Statement=[{Effect="Allow",Principal={Service="ec2.amazonaws.com"},Action="sts:AssumeRole"}]})
}
resource "aws_iam_role_policy_attachment" "node_worker" { count = var.academy_mode ? 0 : 1 role = aws_iam_role.eks_nodes[0].name policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" }
resource "aws_iam_role_policy_attachment" "node_cni" { count = var.academy_mode ? 0 : 1 role = aws_iam_role.eks_nodes[0].name policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" }
resource "aws_iam_role_policy_attachment" "node_ecr" { count = var.academy_mode ? 0 : 1 role = aws_iam_role.eks_nodes[0].name policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" }
resource "aws_iam_policy" "togglemaster_data_access" {
  count = var.academy_mode ? 0 : 1
  name = "${local.name}-data-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["sqs:SendMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:DeleteMessage"], Resource = aws_sqs_queue.togglemaster.arn },
      { Effect = "Allow", Action = ["dynamodb:PutItem", "dynamodb:DescribeTable"], Resource = aws_dynamodb_table.analytics.arn }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "node_data_access" { count = var.academy_mode ? 0 : 1 role = aws_iam_role.eks_nodes[0].name policy_arn = aws_iam_policy.togglemaster_data_access[0].arn }

# ---------------- EKS ----------------
resource "aws_eks_cluster" "this" {
  name = local.name
  role_arn = local.cluster_role_arn
  version = var.cluster_version
  vpc_config { subnet_ids = concat(aws_subnet.private[*].id, aws_subnet.public[*].id) endpoint_private_access = true endpoint_public_access = true }
  access_config { authentication_mode = "API_AND_CONFIG_MAP" }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
  tags = { Project = "ToggleMaster" }
}
resource "aws_eks_node_group" "this" {
  cluster_name = aws_eks_cluster.this.name
  node_group_name = "${local.name}-nodes"
  node_role_arn = local.node_role_arn
  subnet_ids = aws_subnet.private[*].id
  instance_types = ["t3.medium"]
  scaling_config { desired_size = 2 min_size = 1 max_size = 4 }
  update_config { max_unavailable = 1 }
  depends_on = [aws_iam_role_policy_attachment.node_worker, aws_iam_role_policy_attachment.node_cni, aws_iam_role_policy_attachment.node_ecr, aws_iam_role_policy_attachment.node_data_access]
  tags = { Project = "ToggleMaster" }
}

# ---------------- Security groups ----------------
resource "aws_security_group" "data" {
  name = "${local.name}-data" vpc_id = aws_vpc.this.id
  ingress { from_port=5432 to_port=5432 protocol="tcp" security_groups=[aws_eks_cluster.this.vpc_config[0].cluster_security_group_id] }
  ingress { from_port=6379 to_port=6379 protocol="tcp" security_groups=[aws_eks_cluster.this.vpc_config[0].cluster_security_group_id] }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

# ---------------- RDS ----------------
resource "aws_db_subnet_group" "this" { name = "${local.name}-db" subnet_ids = aws_subnet.private[*].id }
resource "aws_db_instance" "postgres" {
  for_each = { auth="auth", flag="flags", targeting="targeting" }
  identifier = "${local.name}-${each.key}-postgres"
  engine = "postgres" engine_version = "16" instance_class = "db.t3.micro"
  allocated_storage = 20 storage_type = "gp3"
  db_name = "${each.value}_db" username = var.db_username password = var.db_password
  port = 5432 publicly_accessible = false skip_final_snapshot = true deletion_protection = false
  db_subnet_group_name = aws_db_subnet_group.this.name vpc_security_group_ids = [aws_security_group.data.id]
  backup_retention_period = 1
  tags = { Service = each.key }
}

# ---------------- Redis ----------------
resource "aws_elasticache_subnet_group" "this" { name = "${local.name}-redis" subnet_ids = aws_subnet.private[*].id }
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.name}-redis" description = "ToggleMaster evaluation cache"
  engine = "redis" engine_version = "7.1" node_type = "cache.t3.micro" num_cache_clusters = 1
  subnet_group_name = aws_elasticache_subnet_group.this.name security_group_ids = [aws_security_group.data.id]
  automatic_failover_enabled = false transit_encryption_enabled = false
}

# ---------------- DynamoDB ----------------
resource "aws_dynamodb_table" "analytics" {
  name = "ToggleMasterAnalytics" billing_mode = "PAY_PER_REQUEST" hash_key = "event_id"
  attribute { name="event_id" type="S" }
  tags = { Service = "analytics-service" }
}

# ---------------- SQS ----------------
resource "aws_sqs_queue" "togglemaster" { name = "togglemaster" visibility_timeout_seconds = 60 message_retention_seconds = 345600 }

# ---------------- ECR ----------------
resource "aws_ecr_repository" "service" {
  for_each = local.services
  name = each.value
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
}

# ---------------- Kubernetes add-ons via Helm ----------------
resource "helm_release" "metrics_server" {
  name="metrics-server" namespace="kube-system" repository="https://kubernetes-sigs.github.io/metrics-server/" chart="metrics-server" version="3.13.0" wait=true
  set { name="args" value="{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP}" }
}
resource "helm_release" "ingress_nginx" {
  name="ingress-nginx" namespace="ingress-nginx" create_namespace=true repository="https://kubernetes.github.io/ingress-nginx" chart="ingress-nginx" version="4.13.0" wait=true
  set { name="controller.service.type" value="LoadBalancer" }
  set { name="controller.service.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-type" value="nlb" }
}
resource "helm_release" "argocd" {
  count=var.enable_argocd ? 1 : 0
  name="argocd" namespace="argocd" create_namespace=true repository="https://argoproj.github.io/argo-helm" chart="argo-cd" version="9.1.6" wait=true
}

# ---------------- Cluster Secret for runtime values ----------------
resource "aws_secretsmanager_secret" "app" { name="${local.name}/runtime" recovery_window_in_days=0 }
resource "aws_secretsmanager_secret_version" "app" {
  secret_id=aws_secretsmanager_secret.app.id
  secret_string=jsonencode({ db_username=var.db_username, db_password=var.db_password, master_key=var.master_key, service_api_key=var.service_api_key })
}

# Argo Application is intentionally generated as a manifest file after apply; see gitops/argocd/application.yaml.
