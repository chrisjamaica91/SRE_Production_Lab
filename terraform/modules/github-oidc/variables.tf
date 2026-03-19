# Variables for GitHub OIDC configuration
# These make the module reusable for different repos/environments

variable "github_org" {
  description = "GitHub organization or username (e.g., 'your-username')"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g., 'SRE_Lab_Enterprise_Level')"
  type        = string
}

variable "github_branches" {
  description = "List of branches allowed to assume this role (e.g., ['main', 'staging'])"
  type        = list(string)
  default     = ["main"]
}

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
  default     = "GitHubActionsRole"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}