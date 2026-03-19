# GitHub OIDC Authentication Module

This Terraform module creates the necessary AWS resources to enable GitHub Actions to authenticate to AWS using OIDC (OpenID Connect) instead of long-lived IAM user credentials.

## 🔒 Security Benefits

- **No long-lived credentials** - No IAM access keys stored in GitHub Secrets
- **Automatic expiration** - Tokens valid for 1 hour only
- **Branch-based permissions** - Restrict which branches can deploy
- **Full audit trail** - CloudTrail logs show exact repo/branch/workflow
- **Least privilege** - Each environment can have separate roles

## 📚 How It Works

1. GitHub Actions workflow requests an OIDC token from GitHub
2. Token contains claims: repository, branch, workflow
3. Workflow presents token to AWS STS
4. AWS validates token signature and checks trust policy
5. If valid, AWS returns temporary credentials (1 hour)
6. Workflow uses credentials to deploy

## 🛠️ Usage

```hcl
module "github_oidc" {
  source = "./modules/github-oidc"

  github_org      = "your-github-username"
  github_repo     = "SRE_Lab_Enterprise_Level"
  github_branches = ["main", "staging"]
  role_name       = "GitHubActionsDeployRole"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Output the role ARN for use in GitHub Actions
output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}