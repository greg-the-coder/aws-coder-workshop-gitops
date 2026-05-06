variable "gh_token" {
  type        = string
  description = "GitHub token for API access. Defaults to empty string if not provided."
  sensitive   = true
  default     = ""
}

variable "gh_username" {
  type        = string
  description = "GitHub username. Defaults to empty string; falls back to Coder workspace owner name."
  sensitive   = true
  default     = ""
}

variable "gh_email" {
  type        = string
  description = "GitHub email. Defaults to empty string; falls back to Coder workspace owner email."
  sensitive   = true
  default     = ""
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces)."
  default     = "coder"
}

data "coder_parameter" "preview_port" {
  name        = "Preview Port"
  description = "The port the web app is running on to preview in Coder Tasks!"
  type        = "number"
  default     = 5173
  mutable     = true
  order       = 10
}

data "coder_parameter" "use_bots_git_creds" {
  name        = "Use Bot's Git Credentials?"
  description = "Use Coder Contrib's Git credentials to clone/pull from repos?"
  type        = "bool"
  default     = true
  mutable     = true
  order       = 11
}

locals {
  memory-card-port = 5173
  memory-card = {
    "Preview Port" = local.memory-card-port
    (data.coder_parameter.use_bots_git_creds.name) = true
  }
}

data "coder_workspace_preset" "memory-card-ohio" {
  name        = "Ohio"
  description = "Work on a Memory Card Game Using AI"
  icon        = "/emojis/1f1fa-1f1f8.png"
  default     = true
  parameters  = merge(local.memory-card, {})
}