provider "aws" { region = var.aws_region }

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }

data "aws_iam_role" "lab" { count = var.academy_mode ? 1 : 0 name = var.lab_role_name }

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" { name = aws_eks_cluster.this.name }
