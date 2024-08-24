# Terraform AWS Configuration

## Description

The "devops-infra" repository provides infrastructure as code (IaC) solutions for managing cloud resources within a DevOps environment.
It is designed to facilitate the deployment and management of essential services such as Amazon ECR (Elastic Container Registry), EKS (Elastic Kubernetes Service), and S3 (Simple Storage Service) using Terraform.
Through automated GitHub Actions workflows, the repository streamlines processes like planning and applying infrastructure changes, ensuring a more efficient and consistent infrastructure deployment strategy.
This setup allows developers and operations teams to easily define, version, and manage their infrastructure alongside their application code, promoting best practices in DevOps.


## Repository Structure

```bash
.
├── README.md
├── backend.tf
├── data.tf
├── ecr
│   ├── backend.tf
│   ├── ecr.tf
│   ├── providers.tf
│   └── variables.tf
├── eks.tf
├── github-actions
│   ├── backend.tf
│   ├── data.tf
│   ├── idp.tf
│   ├── providers.tf
│   ├── roles.tf
│   └── variables.tf
├── local.tf
├── providers.tf
├── s3
│   ├── provider.tf
│   ├── s3.tf
│   └── variables.tf
├── variables.tf
└── vpc.tf
```

# Components
- [S3 Bucket](#s3-bucket)
- [ECR Repository](#ecr-repository)
- [VPC](#vpc)
- [EKS Cluster](#eks-cluster)
- [Github Actions OIDC roles](#github-actions-oidc-roles)
- [Github Actions IAC workflows](#github-actions-iac-workflows)



## S3 Bucket

The `s3` directory contains Terraform configurations for creating S3 bucket for store tfstate files with dynamodb table for terraform lock. 

### Configuration

- **Bucket Name**: `devops-infra-checkpoint`
- **Region**: `eu-west-1`
- **Versioning**: Enabled
- **Encryption**: AES-256
- **Terraform state locking**

**Example**:

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "example"
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```
## ECR Repository

The `ecr` directory contains Terraform configurations for creating private ecr repository for store app docker images.

### Configuration

- **Repository Name**: `example-repo`

**Example**:

```hcl
resource "aws_ecr_repository" "example" {
  name = "example-repo"
}
```
## VPC
 The file `vpc.tf` containts calling to vpc module from terraform registry for creating vpc.
 ### Configuration

 - **VPC CIDR Block**: `192.168.0.0/16`
 - **Subnets**: 2 public and 2 private
 - **NAT Gateway**: Created in public subnets
 - **Internet Gateway**: Created in vpc
 - **Azs**: `eu-west-1a,eu-west-1b`


**Example**:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "example-vpc"
  cidr = "<cidr>

  azs             = "<list_of_azs>"
  private_subnets = "<list_of_subcidrs>"
  public_subnets  = "<list_of_subcidrs>"
  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 // For assign public subnets to eks elb
  }
}
```



 ---
 **📝 Notes**

The dividing to subnets above achieved by using [cidrsubnet function](https://developer.hashicorp.com/terraform/language/functions/cidrsubnet)

 ---

 ## EKS Cluster
 The file `eks.tf` calling to eks module from terraform registry for creating eks.

  ### Configuration

- **Cluster Name**: `checkpoint-eks`
- **Version**: `1.30`
- **Node Group**: `nodes`
- **access_entries**: `arn:aws:iam::061039772474:role/github-actions-cicd-role,arn:aws:iam::061039772474:user/admin`

**Example**:

```hcl
module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "<module_version>"
  cluster_version                          = "<cluster_version>"
  cluster_name                             = "example-cluster"
  cluster_endpoint_public_access           = true 
  enable_cluster_creator_admin_permissions = true // Grant full permission access to eks cluster to creator(user/role that running terraform)
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = null
  }
  access_entries = { 
    github_actions = {
      principal_arn = "<arn_to_grant_permissions_in_eks>"
      policy_associations = {
        policy = {
          policy_arn = "<access_policy_arn>"
          access_scope = {
            namespaces = ["<your_app_namespace>"]
            type       = "namespace"
          }
        }
      }
    }
      admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin"
      policy_associations = {
        policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }

      }
    }
  }
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = "<vpc_id>"
  subnet_ids = "<list_of_private_subnets>"
  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types                        = ["<instance_type>"]
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    nodes = {
      ami_type     = "AL2023_x86_64_STANDARD"
      min_size     = <min_size_of_nodes_in_asg>
      max_size     = <max_size_of_nodes_in_asg>
      desired_size = <desired_size_of_nodes>
    }
  }
}
```
 ---
 **📝 Notes**

For more info about access entries see https://eksctl.io/usage/access-entries/

 ---
## Github Actions OIDC roles
The `github-actions` folder containt terraform configuration files for creating Github Actions OIDC role that used from Github actions workflow for provision AWS infra and for build and deploy the counter-service app.

### Configuration

- **Identity Provider** - `URL for Github Actions authentication, client id and thumbprint`
- **Github Actions OIDC role for provision AWS infra**
- **Github Actions OIDC role for build and deploy counter-service app**


**Example**:

```hcl
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
```

```hcl
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
    values   = ["repo:<org>/<repo>:*"]
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
      resources = ["arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/<ecr_repository_name>"]
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
      resources = ["arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:cluster/<cluster_name>"]
    }
  ]
}
```
```hcl
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
    values   = ["repo:<org>/<repo>:*"]
  }]
  policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
```

## Github Actions IAC workflows

the `.github/workflows` folder including 2 workflows: `Terraform Plan` workflow that running on any push to any branch and `Terraform Apply` workflow that running on pushing only to branch `main`.


### Configuration

- **Apply workflow**: `.github/workflows/IAC-PIPELINE-APPLY.yaml`
- **Plan workflow**: `.github/workflows/IAC-PIPELINE-PLAN.yaml`

**Example**:

```bash
name: Terraform Apply

on:
  workflow_run:
    workflows:
      - "Terraform Plan"
    types:
      - completed
  workflow_dispatch:
env:
  AWS_REGION: <your_aws_region>
jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' 
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: <Github_actions_terraform_oidc_role>
          aws-region: ${{ env.AWS_REGION }}
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.9.1  

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve

```
```bash
name: Terraform Plan
on:
  push:
    branches:
      - '**'
    paths:
      - '*.tf'
  pull_request:
    branches:
      - 'main'
    paths:
      - '*.tf'
  workflow_dispatch:
env:
  AWS_REGION: <your_aws_region>
jobs:
  terraform-plan:
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: <Github_actions_terraform_oidc_role>
          aws-region: ${{ env.AWS_REGION }}
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.9.1

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan
```




