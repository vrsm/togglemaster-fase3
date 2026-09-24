# EKS enxuto para o projeto ToggleMaster.
#
# Estratégia de custo:
# - 1 Managed Node Group
# - 1 node desejado/mínimo
# - t3.small (2 vCPU / 2 GiB)
# - nodes nas subnets públicas para evitar NAT Gateway
# - control plane em subnets privadas
# - endpoint privado + público do EKS
#
# O acesso administrativo ao cluster também é declarado em Terraform
# através de EKS Access Entry.

locals {
  eks_cluster_name = "togglemaster-fase3"
}

resource "aws_iam_role" "eks_cluster" {
  name = "${local.eks_cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.eks_cluster_name}-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_nodes" {
  name = "${local.eks_cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.eks_cluster_name}-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_nodes_worker" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_cni" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_ecr" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_eks_cluster" "main" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.36"

  vpc_config {
    # Control plane ENIs ficam nas subnets privadas.
    subnet_ids = aws_subnet.private[*].id

    # Mantemos ambos para permitir kubectl da máquina local
    # e comunicação privada dos nodes com o control plane.
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster
  ]

  tags = {
    Name    = local.eks_cluster_name
    Project = "ToggleMaster"
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.eks_cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  # Público para eliminar NAT Gateway neste projeto temporário.
  # As subnets públicas têm MapPublicIpOnLaunch=true.
  subnet_ids = aws_subnet.public[*].id

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_worker,
    aws_iam_role_policy_attachment.eks_nodes_cni,
    aws_iam_role_policy_attachment.eks_nodes_ecr
  ]

  tags = {
    Name    = "${local.eks_cluster_name}-nodes"
    Project = "ToggleMaster"
  }
}

# EKS Access Entry para a identidade IAM utilizada no laboratório.
#
# Este recurso já foi criado manualmente na AWS para liberar o kubectl.
# Agora ele passa a ser declarado pelo Terraform para que a configuração
# faça parte da IaC.
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::523694734848:root"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
