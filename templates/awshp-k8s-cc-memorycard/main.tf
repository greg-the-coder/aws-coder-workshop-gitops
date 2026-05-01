data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

locals {
  repo           = "https://github.com/coder-contrib/memory-card-ai-demo.git"
  repo_name      = element(split(".", element(split("/", local.repo), -1)), 0)
  home_folder    = "/home/coder"
  work_folder    = join("/", [local.home_folder, local.repo_name])
  preview_port   = data.coder_parameter.preview_port.value == "" ? 5173 : data.coder_parameter.preview_port.value
  domain         = element(split("/", data.coder_workspace.me.access_url), -1)
  gh_token       = var.gh_token
  gh_username    = var.gh_username != "" ? var.gh_username : data.coder_workspace_owner.me.name
  gh_email       = var.gh_email != "" ? var.gh_email : data.coder_workspace_owner.me.email
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "1.1.1"

  agent_id = coder_agent.main.id
}

module "coder-login-agent" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "1.1.1"

  # agent_id = coder_agent.main-agent.id
  agent_id = coder_agent.main.id
}

locals {
  vscode-web-extensions = [
    "esbenp.prettier-vscode",
  ]
}

resource "coder_script" "vscode" {
  agent_id     = coder_agent.main.id
  display_name = "Setup VS Code Web"
  icon         = "/icon/code.svg"
  run_on_start = true
  script       = <<-EOF
    #!/bin/bash

    set -e

    echo "Setting up VS-Code Web Settings..."


    EXTENSIONS=("${join(",", local.vscode-web-extensions)}")
    IFS=',' read -r -a EXTENSIONLIST <<< "$${EXTENSIONS}"
    for extension in "$${EXTENSIONLIST[@]}"; do
      if [ -z "$extension" ]; then
        continue
      fi
      printf "Installing extension $${CODE}$extension$${RESET}...\n"
      output=$(code-server --install-extension "$extension" --force)
      if [ $? -ne 0 ]; then
        echo "Failed to install extension: $extension: $output"
      fi
    done
  EOF
}

locals {
  coder_agent_agent_envs = merge({
    CLAUDE_CODE_USE_BEDROCK    = "1"
    ANTHROPIC_MODEL            = "claude-opus-4-5"
    ANTHROPIC_SMALL_FAST_MODEL = "claude-haiku-4-5"
    COLORTERM                  = true
  }, {})
  coder_agent_main_envs = merge({
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
    GIT_CONFIG_COUNT    = 1
    GIT_CONFIG_KEY_0    = "user.name"
    GIT_CONFIG_VALUE_0  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_CONFIG_KEY_1    = "user.email"
    GIT_CONFIG_VALUE_1  = data.coder_workspace_owner.me.email
    GH_USERNAME         = local.gh_username
    GH_TOKEN = var.gh_token
  }, {})
}

module "git-clone" {
  source   = "registry.coder.com/coder/git-clone/coder"
  version  = "1.2.3"

  agent_id = coder_agent.main.id
  url      = local.repo
  base_dir = local.home_folder
}

module "vscode-web" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/vscode-web/coder"
  version  = "1.3.1"

  extensions              = local.vscode-web-extensions
  offline                 = false
  accept_license          = true
  auto_install_extensions = true
  use_cached              = true

  agent_id = coder_agent.main.id
  folder   = local.work_folder
  order    = 996
  group    = "Web Editors"
}

module "vscode-desktop" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/vscode-desktop/coder"
  version  = "1.2.1"

  agent_id = coder_agent.main.id
  folder   = local.work_folder
  order    = 997
  group    = "Desktop IDEs"
}

module "filebrowser" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/filebrowser/coder"
  version  = "1.1.4"

  agent_id = coder_agent.main.id
  order    = 999
}


locals {
  agent_app_slug = "agent"
  agent_app_work_path = "${local.home_folder}"
  agent_app_config_path = "${local.home_folder}/.claude.json"
  agent_app_claude_md_path = "${local.home_folder}/.claude/CLAUDE.md"
  agent_app_system_md = <<-EOF
    Send a task status update to notify the user that you are ready for input, and then wait for user input.
  EOF
}

data "coder_task" "me" {}

resource "coder_script" "agent" {
  agent_id = coder_agent.main.id
  display_name = "AI Agent Setup"
  icon         = "/icon/claude.svg"
  run_on_start = true
  script       = <<-EOF
    #!/bin/bash

    set -e

    echo "Setting up AI Agent Settings..."

    ln -sf /usr/local/bin/claude "$CODER_SCRIPT_BIN_DIR/claude"
    chmod +x "$CODER_SCRIPT_BIN_DIR/claude"

    ARG_CODER_MCP_CLAUDE_SYSTEM_PROMPT=$(mktemp)
    ARG_CODER_MCP_CLAUDE_CODER_PROMPT=$(mktemp)
    
    echo ${base64encode(local.agent_app_system_md)} | base64 -d > "$ARG_CODER_MCP_CLAUDE_SYSTEM_PROMPT"
    echo ${base64encode(data.coder_task.me.prompt)} | base64 -d > "$ARG_CODER_MCP_CLAUDE_CODER_PROMPT"

    coder exp mcp configure claude-code ${local.agent_app_work_path} \
      --auth=token \
      --agent-token=$CODER_AGENT_TOKEN \
      --agent-url=$CODER_AGENT_URL \
      --claude-app-status-slug=${local.agent_app_slug} \
      --claude-api-key=${data.coder_workspace_owner.me.session_token} \
      --claude-config-path=${local.agent_app_config_path} \
      --claude-md-path=${local.agent_app_claude_md_path} \
      --claude-system-prompt="$(cat $ARG_CODER_MCP_CLAUDE_SYSTEM_PROMPT)" \
      --claude-coder-prompt="$(cat $ARG_CODER_MCP_CLAUDE_CODER_PROMPT)"
    
    echo "Done!"
  EOF
}

resource "coder_app" "agent" {
  agent_id = coder_agent.main.id
  slug         = local.agent_app_slug
  display_name = "AI Agent"
  icon         = "/icon/claude.svg"
  command      = <<-EOF
    #!/bin/bash

    set -e

    cd ${local.work_folder}

    /usr/local/bin/claude -c 2>/dev/null || /usr/local/bin/claude 2>/dev/null
  EOF
  share        = "owner"
  open_in      = "tab"
  order        = 2
}

resource "coder_ai_task" "agent" {
  count = data.coder_task.me.enabled ? 1 : 0
  app_id = coder_app.agent.id
}

module "portabledesktop" {
  source   = "registry.coder.com/coder/portabledesktop/coder"
  version  = "0.1.0"
  agent_id = coder_agent.main.id
}

resource "coder_script" "preview" {
  agent_id = coder_agent.main.id
  display_name = "Preview Setup"
  icon         = "/emojis/1f50e.png"
  run_on_start = true
  script       = <<-EOF
    #!/bin/bash

    set -e

    sleep 3s # Wait for Git repository to download
    cd ${local.work_folder}
    git fetch
    # Check for uncommitted changes
    if git diff-index --quiet HEAD -- && \
      [ -z "$(git status --porcelain --untracked-files=no)" ] && \
      [ -z "$(git log --branches --not --remotes)" ]; then
      echo "Repo is clean. Pulling latest changes..."
      git pull
    else
      echo "Repo has uncommitted or unpushed changes. Skipping pull."
    fi
    git remote set-url origin ${local.repo}

    npm install
    nohup npm run dev >/tmp/memory-card.out 2>/tmp/memory-card.err &
    echo $! > /tmp/memory-card.pid
  EOF
}

resource "coder_app" "preview" {
  agent_id     = coder_agent.main.id
  slug         = "preview"
  display_name = "Preview App"
  icon         = "/emojis/1f50e.png"
  url          = "http://localhost:${local.preview_port}"
  share        = "authenticated"
  subdomain    = true
  open_in      = "tab"
  order        = 1
  healthcheck {
    url       = "http://localhost:${local.preview_port}/"
    interval  = 5
    threshold = 15
  }
}