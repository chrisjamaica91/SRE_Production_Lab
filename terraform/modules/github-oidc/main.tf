# ============================================================================
# GitHub OIDC Provider
# ============================================================================
# This tells AWS to trust GitHub's OIDC identity provider
# GitHub's OIDC endpoint: https://token.actions.githubusercontent.com

resource "aws_iam_openid_connect_provider" "github" {
  # The URL of GitHub's OIDC provider (this is standard for all GitHub Actions)
  url = "https://token.actions.githubusercontent.com"

  # Client ID - for GitHub Actions, this is always "sts.amazonaws.com"
  # This means "GitHub Actions wants to assume AWS roles via STS"
  client_id_list = [
    "sts.amazonaws.com"
  ]

  # Thumbprint - verifies the SSL certificate of GitHub's OIDC endpoint
  # This specific thumbprint is for GitHub's token.actions.githubusercontent.com
  # You can verify it with: echo | openssl s_client -servername token.actions.githubusercontent.com -connect token.actions.githubusercontent.com:443 2>&- | openssl x509 -fingerprint -sha1 -noout
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = merge(
    var.tags,
    {
      Name = "github-actions-oidc-provider"
    }
  )
}

# ============================================================================
# IAM Role for GitHub Actions
# ============================================================================
# This role will be assumed by your GitHub Actions workflow

resource "aws_iam_role" "github_actions" {
  name        = var.role_name
  description = "Role assumed by GitHub Actions for CI/CD deployments"

  # Trust policy: defines WHO can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # Only allow requests from GitHub's OIDC provider for AWS STS
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # CRITICAL SECURITY: Only allow specific repo and branches
            # This says: "Only GitHub Actions from repo X on branches Y can assume this role"
            # Format: repo:<org>/<repo>:ref:refs/heads/<branch>
            "token.actions.githubusercontent.com:sub" = [
              for branch in var.github_branches :
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
            ]
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# ============================================================================
# IAM Policy: ECS/ECR Deployment Permissions
# ============================================================================
# This defines WHAT the role can do once assumed

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "github-actions-deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ECR - Push Docker images
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",           # Login to ECR
          "ecr:BatchCheckLayerAvailability",     # Check if image layers exist
          "ecr:GetDownloadUrlForLayer",          # Pull images
          "ecr:BatchGetImage",                   # Pull images
          "ecr:PutImage",                        # Push images
          "ecr:InitiateLayerUpload",            # Upload image layers
          "ecr:UploadLayerPart",                # Upload image layers
          "ecr:CompleteLayerUpload"             # Finalize layer upload
        ]
        Resource = "*"
      },
      # ECS - Deploy applications
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",                   # Update service with new image
          "ecs:DescribeServices",                # Check service status
          "ecs:DescribeTasks",                   # Check task status
          "ecs:ListTasks",                       # List running tasks
          "ecs:RegisterTaskDefinition",          # Create new task definition
          "ecs:DescribeTaskDefinition"          # Read task definition
        ]
        Resource = "*"
      },
      # IAM - Pass role to ECS tasks
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      # CloudFormation - For infrastructure updates (optional)
      {
        Effect = "Allow"
        Action = [
          "cloudformation:DescribeStacks",
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStackEvents"
        ]
        Resource = "*"
      },
      # S3 - For Terraform state and artifact storage
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}