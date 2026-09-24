# ------------------------------------------------------------
# EKS Pod Identity Agent
# ------------------------------------------------------------

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name    = "${local.eks_cluster_name}-pod-identity-agent"
    Project = "ToggleMaster"
  }
}

# ============================================================
# evaluation-service
# ============================================================

# ------------------------------------------------------------
# IAM Role
# ------------------------------------------------------------

data "aws_iam_policy_document" "evaluation_service_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "evaluation_service" {
  name = "${local.eks_cluster_name}-evaluation-service-role"

  assume_role_policy = data.aws_iam_policy_document.evaluation_service_assume_role.json

  tags = {
    Name    = "${local.eks_cluster_name}-evaluation-service-role"
    Project = "ToggleMaster"
    Service = "evaluation-service"
  }
}

# ------------------------------------------------------------
# Permissão mínima: publicar no SQS
# ------------------------------------------------------------

data "aws_iam_policy_document" "evaluation_service_sqs" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.togglemaster.arn
    ]
  }
}

resource "aws_iam_role_policy" "evaluation_service_sqs" {
  name = "${local.eks_cluster_name}-evaluation-service-sqs"

  role   = aws_iam_role.evaluation_service.id
  policy = data.aws_iam_policy_document.evaluation_service_sqs.json
}

# ------------------------------------------------------------
# Pod Identity Association
# ------------------------------------------------------------

resource "aws_eks_pod_identity_association" "evaluation_service" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "togglemaster"
  service_account = "evaluation-service"
  role_arn        = aws_iam_role.evaluation_service.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent
  ]
}

# ============================================================
# analytics-service
# ============================================================

# ------------------------------------------------------------
# IAM Role
# ------------------------------------------------------------

data "aws_iam_policy_document" "analytics_service_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "analytics_service" {
  name = "${local.eks_cluster_name}-analytics-service-role"

  assume_role_policy = data.aws_iam_policy_document.analytics_service_assume_role.json

  tags = {
    Name    = "${local.eks_cluster_name}-analytics-service-role"
    Project = "ToggleMaster"
    Service = "analytics-service"
  }
}

# ------------------------------------------------------------
# Permissões mínimas no SQS
# ------------------------------------------------------------

data "aws_iam_policy_document" "analytics_service_sqs" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [
      aws_sqs_queue.togglemaster.arn
    ]
  }
}

resource "aws_iam_role_policy" "analytics_service_sqs" {
  name = "${local.eks_cluster_name}-analytics-service-sqs"

  role   = aws_iam_role.analytics_service.id
  policy = data.aws_iam_policy_document.analytics_service_sqs.json
}

# ------------------------------------------------------------
# Permissões mínimas no DynamoDB
# ------------------------------------------------------------

data "aws_iam_policy_document" "analytics_service_dynamodb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:DescribeTable"
    ]

    resources = [
      aws_dynamodb_table.analytics.arn
    ]
  }
}

resource "aws_iam_role_policy" "analytics_service_dynamodb" {
  name = "${local.eks_cluster_name}-analytics-service-dynamodb"

  role   = aws_iam_role.analytics_service.id
  policy = data.aws_iam_policy_document.analytics_service_dynamodb.json
}

# ------------------------------------------------------------
# Pod Identity Association
# ------------------------------------------------------------

resource "aws_eks_pod_identity_association" "analytics_service" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "togglemaster"
  service_account = "analytics-service"
  role_arn        = aws_iam_role.analytics_service.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent
  ]
}
