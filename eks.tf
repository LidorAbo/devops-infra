module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "20.24.0"
  cluster_version                          = "1.30"
  cluster_name                             = local.cluster_name
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = null
  }
  access_entries = {
    github_actions = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-cicd-role"
      policy_associations = {
        policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            namespaces = ["default"]
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

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types                        = ["t2.micro"]
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    nodes = {
      ami_type     = "AL2023_x86_64_STANDARD"
      min_size     = 1
      max_size     = 20
      desired_size = 20
    }
  }
}