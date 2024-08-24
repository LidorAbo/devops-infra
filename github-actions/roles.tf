module "github_actions_ci_cd_role" {
  source  = "mineiros-io/iam-role/aws"
  version = "~> 0.6.0"

  name = "github-actions-cicd-role"

  assume_role_principals = [{
    type        = "Federated"
    identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
  }]
  assume_role_actions = ["sts:AssumeRoleWithWebIdentity"]
  assume_role_conditions = [{
    test     = "StringEquals"
    variable = "token.actions.githubusercontent.com:aud"
    values   = ["sts.amazonaws.com"]
    }, {
    test     = "StringLike"
    variable = "token.actions.githubusercontent.com:sub"
    values   = ["repo:LidorAbo/counter-service:*"]
  }]

  policy_statements = [
    {
      sid    = "ECRAccess"
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
    },
    {
      sid       = "ECRAuthToken"
      effect    = "Allow"
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    },
    {
      sid    = "EKSAccess"
      effect = "Allow"
      actions = ["eks:DescribeCluster",
      "eks:UpdateClusterConfig"]
      resources = ["arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:cluster/${var.company_name}-eks"]
    }
  ]
}
module "github_actions_terraform_role" {
  source  = "mineiros-io/iam-role/aws"
  version = "~> 0.6.0"
  name    = "github-actions-terraform-role"
  assume_role_principals = [{
    type        = "Federated"
    identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
  }]
  assume_role_actions = ["sts:AssumeRoleWithWebIdentity"]
  assume_role_conditions = [{
    test     = "StringEquals"
    variable = "token.actions.githubusercontent.com:aud"
    values   = ["sts.amazonaws.com"]
    }, {
    test     = "StringLike"
    variable = "token.actions.githubusercontent.com:sub"
    values   = ["repo:LidorAbo/devops-infra:*"]
  }]
  policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}