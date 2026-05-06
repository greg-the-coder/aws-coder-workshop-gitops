terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "2.37.1"
        }
        coder = {
            source  = "coder/coder"
            version = ">= 2.13"
        }
        random = {
            source = "hashicorp/random"
            version = "3.7.2"
        }
    }
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces)."
  default     = "coder"
}



data "coder_task" "me" {}

locals {
  home_dir = "/home/coder"
  bin_path = "/home/coder/.local/bin:/home/coder/bin:/home/coder/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  cost     = 2
  port     = 3000
  domain   = element(split("/", data.coder_workspace.me.access_url), -1)
  
  task_prompt = join(" ", [
    "First, post a 'task started' update to Coder.",
    "Then, review all of your memory.",
    "Finally, ${data.coder_task.me.prompt}.",
  ])
  
  system_prompt = <<-EOT
    Hey! First, report an initial task to Coder to show you have started! The user has provided you with a prompt of something to create. Create it the best you can, and keep it as succinct as possible.
    
    If you're being tasked to create a web application, then:
    - ALWAYS start the server using `python3` or `node` on localhost:${local.port}.
    - BEFORE starting the server, ALWAYS attempt to kill ANY process using port ${local.port}, and then run the dev server on port ${local.port}.
    - ALWAYS build the project using dev servers (and ALWAYS VIA desktop-commander)
    - When finished, you should use Playwright to review the HTML to ensure it is working as expected.

    ALWAYS run long-running commands (e.g. `pnpm dev` or `npm run dev`) using desktop-commander so it runs it in the background and users can prompt you.  Other short-lived commands (build, test, cd, write, read, view, etc) can run normally.

    NEVER run the dev server without desktop-commander.

    For previewing, always use the dev server for fast feedback loops (never do a full Next.js build, for exmaple). A simple HTML/static is preferred for web applications, but pick the best AND lightest framework for the job.
    
    The dev server will ALWAYS be on localhost:${local.port} and NEVER start on another port. If the dev server crashes for some reason, kill port ${local.port} (or the desktop-commander session) and restart the dev server.

    After large changes, use Playwright to ensure your changes work (preview localhost:${local.port}). Take a screenshot, look at the screenshot. Also look at the HTML output from Playwright. If there are errors or something looks "off," fix it.
    
    Aim to autonomously investigate and solve issues the user gives you and test your work, whenever possible.
    
    Avoid shortcuts like mocking tests. When you get stuck, you can ask the user but opt for autonomy.
    
    In your task reports to Coder:
    - Be specific about what you're doing
    - Clearly indicate what information you need from the user when in "failure" state
    - Keep it under 160 characters
    - Make it actionable

    If you're being tasked to create a Coder template, then,
    - You must ALWAYS ask the user for permission to push it. 
    - You are NOT allowed to push templates OR create workspaces from them without the users explicit approval.

    If you're being tasked to create additional Coder tasks or workspaces, ALWAYS use `coder task create` instead of `coder create`.
    - Example: coder task create --template "awshp-k8s-with-claude-code" "<your prompt here>"

    When reporting URLs to Coder, report to "https://preview--dev--${data.coder_workspace.me.name}--${data.coder_workspace_owner.me.name}.${local.domain}/" that proxies port ${local.port}
  EOT
}

# Minimum vCPUs needed 
data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores for your individual workspace"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min = 2
    max = 8
  }
  form_type = "input"
  mutable   = true
  default   = 4
  order     = 1
}

# Minimum GB memory needed 
data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Memory (__ GB) for your individual workspace"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min = 4
    max = 16
  }
  form_type = "input"
  mutable   = true
  default   = 8
  order     = 2
}

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage for '${local.home_dir}'! This will persist after the workspace's K8s Pod is shutdown or deleted."
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 10
    max       = 50
    monotonic = "increasing"
  }
  form_type = "slider"
  mutable   = true
  default   = 30
  order     = 3
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_env" "agent_envs" {
  for_each = {
    CLAUDE_CODE_USE_BEDROCK = "1"
    ANTHROPIC_MODEL         = "us.anthropic.claude-opus-4-6-v1"
    PATH                    = local.bin_path
  }
  agent_id = coder_agent.dev.id
  name     = each.key
  value    = each.value
}

resource "coder_agent" "dev" {
    arch = "amd64"
    os = "linux"
    dir = local.home_dir
    display_apps {
        vscode          = false
        vscode_insiders = false
        web_terminal    = true
        ssh_helper      = false
    }
    startup_script = <<-EOT
    set -e

    # Wait for Claude Code MCP setup to complete
    timeout 60 bash -c 'until [ -f ${local.agent_app_config_path} ]; do sleep 2; done'

    CODER_PROMPT_FILE="/tmp/coder_prompt.txt"
    echo ${base64encode(data.coder_task.me.prompt)} | base64 -d > "$CODER_PROMPT_FILE"
    TASK_PROMPT=$(cat "$CODER_PROMPT_FILE" 2>/dev/null | tr -d '[:space:]')

    # Start Claude in a persistent tmux session (async, background)
    if ! tmux has-session -t claude 2>/dev/null; then
      if [ -n "$TASK_PROMPT" ]; then
        tmux new-session -d -s claude -x 220 -y 50 \
          "claude --dangerously-skip-permissions \"$(cat $CODER_PROMPT_FILE)\""
      else
        tmux new-session -d -s claude -x 220 -y 50 \
          "claude --dangerously-skip-permissions"
      fi
    fi
    EOT

}

module "coder-login" {
    source   = "registry.coder.com/coder/coder-login/coder"
    version  = "1.1.0"
    agent_id = coder_agent.dev.id
}

module "code-server" {
    source   = "registry.coder.com/coder/code-server/coder"
    version  = "1.3.1"
    agent_id       = coder_agent.dev.id
    folder         = local.home_dir
    subdomain = false
    order = 0
}

module "kiro" {
    source   = "registry.coder.com/coder/kiro/coder"
    version  = "1.1.0"
    agent_id = coder_agent.dev.id
    order = 1
}

locals {
  agent_app_slug        = "claude-code"
  agent_app_config_path = "${local.home_dir}/.claude.json"
  agent_app_claude_md_path = "${local.home_dir}/.claude/CLAUDE.md"
}

resource "coder_script" "claude-code-setup" {
  agent_id     = coder_agent.dev.id
  display_name = "Claude Code Setup"
  icon         = "/icon/claude.svg"
  run_on_start = true
  script       = <<-EOF
    #!/bin/bash
    set -e

    # Symlink claude and coder binaries
    ln -sf "$(which claude)" "$CODER_SCRIPT_BIN_DIR/claude"
    chmod +x "$CODER_SCRIPT_BIN_DIR/claude"
    ln -sf /tmp/coder.*/coder "$CODER_SCRIPT_BIN_DIR/coder"

    # Safety net: install AWS CLI if not present
    if ! command -v aws &>/dev/null; then
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
      unzip -q /tmp/awscliv2.zip -d /tmp
      sudo /tmp/aws/install
      rm -rf /tmp/aws /tmp/awscliv2.zip
    fi

    # Safety net: install AWS CDK if not present
    if ! command -v cdk &>/dev/null; then
      sudo npm install -g aws-cdk
    fi

    # Write system prompt and task prompt to temp files for MCP config
    ARG_SYSTEM_PROMPT=$(mktemp)
    ARG_TASK_PROMPT=$(mktemp)
    echo ${base64encode(local.system_prompt)} | base64 -d > "$ARG_SYSTEM_PROMPT"
    echo ${base64encode(local.task_prompt)} | base64 -d > "$ARG_TASK_PROMPT"

    coder exp mcp configure claude-code ${local.home_dir} \
      --auth=token \
      --agent-token=$CODER_AGENT_TOKEN \
      --agent-url=$CODER_AGENT_URL \
      --claude-app-status-slug=${local.agent_app_slug} \
      --claude-api-key=${data.coder_workspace_owner.me.session_token} \
      --claude-config-path=${local.agent_app_config_path} \
      --claude-md-path=${local.agent_app_claude_md_path} \
      --claude-system-prompt="$(cat $ARG_SYSTEM_PROMPT)" \
      --claude-coder-prompt="$(cat $ARG_TASK_PROMPT)"

    echo "Claude Code MCP configuration complete."
  EOF
}

resource "coder_app" "claude-code" {
  agent_id     = coder_agent.dev.id
  slug         = local.agent_app_slug
  display_name = "Claude Code"
  icon         = "/icon/claude.svg"
  command      = "tmux attach-session -t claude"
  share        = "owner"
  open_in      = "tab"
  order        = 999
}

resource "coder_ai_task" "claude-code" {
  count  = data.coder_task.me.enabled ? 1 : 0
  app_id = coder_app.claude-code.id
}

resource "coder_app" "preview" {
    agent_id     = coder_agent.dev.id
    slug         = "preview"
    display_name = "Preview your app"
    icon         = "${data.coder_workspace.me.access_url}/emojis/1f50e.png"
    url          = "http://localhost:${local.port}"
    share        = "authenticated"
    subdomain    = false
    open_in      = "tab"
    order = 3
    healthcheck {
        url       = "http://localhost:${local.port}/"
        interval  = 5
        threshold = 15
    }
}

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace_owner.me.id
      "com.coder.user.username"  = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "dev" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home
  ]
  wait_for_rollout = false
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "coder-workspace"
        "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
        "app.kubernetes.io/part-of"  = "coder"
        "com.coder.resource"         = "true"
        "com.coder.workspace.id"     = data.coder_workspace.me.id
        "com.coder.workspace.name"   = data.coder_workspace.me.name
        "com.coder.user.id"          = data.coder_workspace_owner.me.id
        "com.coder.user.username"    = data.coder_workspace_owner.me.name
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "coder-workspace"
          "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
          "app.kubernetes.io/part-of"  = "coder"
          "com.coder.resource"         = "true"
          "com.coder.workspace.id"     = data.coder_workspace.me.id
          "com.coder.workspace.name"   = data.coder_workspace.me.name
          "com.coder.user.id"          = data.coder_workspace_owner.me.id
          "com.coder.user.username"    = data.coder_workspace_owner.me.name
        }
      }
      spec {
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }
        service_account_name = "coder"
        container {
          name              = "dev"
          image             = "public.ecr.aws/f7a1d7a4/coder-aienv:1.1.5"
          image_pull_policy = "Always"
          command           = ["sh", "-c", coder_agent.dev.init_script]
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.dev.token
          }
          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "512Mi"
            }
            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
          }
          volume_mount {
            mount_path = local.home_dir
            name       = "home"
            read_only  = false
          }
        }

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
            read_only  = false
          }
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "coder_metadata" "pod_info" {
    count = data.coder_workspace.me.start_count
    resource_id = kubernetes_deployment.dev[0].id
    daily_cost = local.cost
}
