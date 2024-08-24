data "aws_iam_policy_document" "ecr_helm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/${var.company_name}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = ["arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:cluster/${var.company_name}-eks"]
  }
}
data "aws_caller_identity" "current" {}