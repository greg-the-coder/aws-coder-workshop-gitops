locals {
  ws_name = "coder-ws-${data.coder_workspace.me.id}"
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
    "com.coder.user.email"     = data.coder_workspace_owner.me.email
    "com.coder.workspace.id"   = data.coder_workspace.me.id
    "com.coder.workspace.name" = data.coder_workspace.me.name
    "com.coder.user.id"        = data.coder_workspace_owner.me.id
    "com.coder.user.username"  = data.coder_workspace_owner.me.name
  }
}

resource "coder_metadata" "pod_info" {
  resource_id = try(kubernetes_deployment_v1.this[0].id, "")
  item {
    key   = "Workspace UUID"
    value = local.ws_name
  }
}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  connection_timeout = 300
  dir  = local.home_folder

  display_apps {
    vscode          = false
    vscode_insiders = false
    web_terminal    = true
    ssh_helper      = false
  }

  metadata {
    display_name = "CPU Usage (Workspace)"
    key          = "cpu_usage"
    order        = 0
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage (Workspace)"
    key          = "ram_usage"
    order        = 1
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk Usage (Host)"
    key          = "disk_host"
    order        = 6
    script       = "coder stat disk --path / --prefix Gi"
    interval     = 600
    timeout      = 10
  }
}

resource "coder_env" "main" {
  for_each = local.coder_agent_main_envs
  agent_id = coder_agent.main.id
  name     = each.key
  value    = each.value
}

# resource "coder_agent" "main-agent" {
#   arch = "amd64"
#   os   = "linux"
#   connection_timeout = 300
#   dir  = local.home_folder

#   display_apps {
#     vscode          = false
#     vscode_insiders = false
#     web_terminal    = false
#     ssh_helper      = false
#   }

#   metadata {
#     display_name = "CPU Usage (Workspace)"
#     key          = "cpu_usage"
#     order        = 0
#     script       = "coder stat cpu"
#     interval     = 10
#     timeout      = 1
#   }

#   metadata {
#     display_name = "RAM Usage (Workspace)"
#     key          = "ram_usage"
#     order        = 1
#     script       = "coder stat mem"
#     interval     = 10
#     timeout      = 1
#   }

#   metadata {
#     display_name = "Disk Usage (Host)"
#     key          = "disk_host"
#     order        = 6
#     script       = "coder stat disk --path / --prefix Gi"
#     interval     = 600
#     timeout      = 10
#   }
# }

resource "coder_env" "agent" {
  for_each = local.coder_agent_agent_envs
  # agent_id = coder_agent.main-agent.id
  agent_id = coder_agent.main.id
  name     = each.key
  value    = each.value
}

locals {
  ws_img         = "public.ecr.aws/f7a1d7a4/coder-aienv:1.1.5"

  # ── Home directory file seeding ──────────────────────────────────────
  # Files are written by coder_script.seed_home on workspace start.
  # All content is inlined here so the template is fully self-contained
  # and does not depend on external files being bundled by the provisioner.
  #
  # Each entry: path relative to $HOME, content string, and octal mode.

  home_seed_files = {

    # ── .claude.json (templated: home_folder) ──
    ".claude.json" = {
      content = jsonencode({
        numStartups              = 1
        lastOnboardingVersion    = "2.1.83"
        hasCompletedOnboarding   = true
        projects = {
          (local.home_folder) = {
            hasTrustDialogAccepted                    = true
            allowedTools                               = []
            mcpContextUris                             = []
            mcpServers                                 = {}
            enabledMcpjsonServers                      = []
            disabledMcpjsonServers                     = []
            projectOnboardingSeenCount                 = 1
            hasClaudeMdExternalIncludesApproved        = false
            hasClaudeMdExternalIncludesWarningShown    = false
            exampleFiles                               = []
          }
        }
      })
      mode = "0666"
    }

    # ── .mcp.json (templated: gh_token) ──
    ".mcp.json" = {
      content = jsonencode({
        mcpServers = {
          github = {
            type    = "http"
            url     = "https://api.githubcopilot.com/mcp"
            headers = { Authorization = "Bearer ${local.gh_token}" }
          }
          playwright = {
            command = "npx"
            args    = ["@playwright/mcp@latest"]
          }
        }
      })
      mode = "0666"
    }

    # ── AGENTS.md (templated: work_folder, preview_port) ──
    "AGENTS.md" = {
      content = <<-MD
## Framing

You are a helpful coding assistant working on the Memory Card AI Demo application. Aim to autonomously investigate and solve issues the user gives you, and test your work whenever possible.

ALWAYS wait for the user to ask you what to work on. NEVER jump to conclusions on what to work on without the user's direction.

Stay on track. Feel free to debug, but when the original plan fails, do not choose a different route or architecture without checking with the user first.

ALWAYS check if there's a CLAUDE.md, AGENTS.md, or README.md file in your current directory. Thoroughly read and understand them before making changes.

Avoid shortcuts like mocking tests. When you get stuck, you can ask the user but opt for autonomy.

## Tool Selection

- **Playwright**: Use for previewing your changes after you made them to confirm it worked as expected
- **Built-in tools**: Use for everything else (file operations, git commands, builds & installs, one-off shell commands)

When you need to access the GitHub API (e.g., to query GitHub issues or pull requests), use the GitHub CLI (`gh`). The GitHub CLI is already authenticated. Use `gh api` for any REST API calls. The GitHub token is also available as `GH_TOKEN`.

You can execute git commands, and your git configurations are stored in environment variables prefixed with `GIT_` and `GH_`.

## Context

There is an existing Vite application in the `${local.work_folder}` directory. The app runs via `npm run dev` on port **${local.preview_port}** (configurable via workspace parameters).

Be sure to read CLAUDE.md before making any changes.

## Startup Responsibilities

When you first start, you are responsible for ensuring the application is running:

1. Check if the dev server is already running: `lsof -i :${local.preview_port}`
2. If not running, start it immediately:
   ```bash
   cd ~/${local.work_folder}
   npm install  # Only if node_modules is missing
   nohup npm run dev >/tmp/memory-card.out 2>/tmp/memory-card.err &
   echo $! > /tmp/memory-card.pid
   ```
3. Verify the server started successfully by checking the output or port
4. Report to the user that the application is ready

Do this before waiting for further user instructions.

### Browser Preview

After the dev server is confirmed running, open the app in the desktop browser so users can preview it immediately:

1. Use `spawn_computer_use_agent` to navigate to `http://localhost:${local.preview_port}/` and confirm the page loads.
2. Wait for the agent to complete using `wait_agent` before proceeding.

The app is also viewable in the Coder UI via the configured Preview Port (${local.preview_port}).

### Running the Development Server

Before starting any server or long-running process:

1. Always check for running processes before starting new ones
2. Verify status of running services before executing duplicate commands
3. Update your todo list to reflect the current state accurately

If you need to restart the dev server:

1. Check if the server is already running: `lsof -i :${local.preview_port}`
2. Kill existing process if needed: `kill $(lsof -t -i :${local.preview_port})`
3. Start the server in the background:
   ```bash
   cd ~/${local.work_folder}
   nohup npm run dev >/tmp/memory-card.out 2>/tmp/memory-card.err &
   echo $! > /tmp/memory-card.pid
   ```

### Demo Application Notes

This application is for demo purposes. When the user is previewing the homepage and subsequent pages, aim to make visual, backend, or logic changes quickly so the user can preview them. The user will add more details as needed.

Do not extensively test the application unless asked. Focus on applying changes and having the user review what was made. You can still push and commit changes as needed.

You are allowed to download and push content anywhere as needed or requested by the user.
      MD
      mode = "0666"
    }

    # ── .vscode-server/data/Machine/settings.json (static) ──
    ".vscode-server/data/Machine/settings.json" = {
      content = jsonencode({
        "workbench.colorTheme"                     = "Default Dark Modern"
        "workbench.preferredDarkColorTheme"        = "Default Dark Modern"
        "workbench.preferredHighContrastColorTheme" = "Default High Contrast"
        "git.useIntegratedAskPass"                 = false
        "github.gitAuthentication"                 = false
        "security.workspace.trust.enabled"         = false
      })
      mode = "0666"
    }
  }
}

# Seed home directory dotfiles and scripts via a startup script.
# This replaces the previous ConfigMap + init-container approach so the
# template works within the default Coder Helm RBAC (pods, PVCs,
# deployments) without requiring configmaps permissions.
resource "coder_script" "seed_home" {
  agent_id     = coder_agent.main.id
  display_name = "Seed Home Directory"
  icon         = "/emojis/1f4c2.png"
  run_on_start = true
  script = <<-SCRIPT
    #!/bin/bash
    set -e

    echo "Seeding home directory files..."

    %{for path, info in local.home_seed_files~}
    # ${path}
    mkdir -p "$(dirname "${local.home_folder}/${path}")"
    echo '${base64encode(info.content)}' | base64 -d > "${local.home_folder}/${path}"
    chmod ${info.mode} "${local.home_folder}/${path}"
    %{endfor~}

    echo "Home directory seeding complete."
  SCRIPT
}

resource "kubernetes_deployment_v1" "this" {
  count            = data.coder_workspace.me.start_count
  depends_on = [ kubernetes_persistent_volume_claim_v1.home ]
  wait_for_rollout = false
  metadata {
    name        = local.ws_name
    namespace   = var.namespace
    labels      = local.labels
    annotations = local.annotations
  }
  spec {
    replicas = 1

    selector {
      match_labels = local.labels
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels      = local.labels
        annotations = local.annotations
      }
      spec {

        termination_grace_period_seconds = 0

        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }

        service_account_name = "coder"

        container {
          name              = "coder"
          image             = local.ws_img
          image_pull_policy = "IfNotPresent"
          command = ["sh", "-c", join("\n", [
            try(coder_agent.main.init_script, "")
          ])]

          security_context {
            run_as_user                = 1000
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false
          }

          resources {
            limits = {
              cpu               = "2"
              memory            = "4Gi"
            }
            requests = {
              cpu               = "2"
              memory            = "4Gi"
            }
          }

          volume_mount {
            mount_path = "${local.home_folder}"
            name       = "home"
            read_only  = false
          }

          dynamic "env" {
            for_each = { CODER_AGENT_TOKEN = try(coder_agent.main.token, "") }
            content {
              name  = env.key
              value = env.value
            }
          }
        }

        # container {
        #   name              = "agent"
        #   image             = local.ws_img
        #   image_pull_policy = "IfNotPresent"
        #   command = ["sh", "-c", join("\n", [
        #     try(coder_agent.main-agent.init_script, "")
        #   ])]

        #   security_context {
        #     run_as_user                = 1000
        #     allow_privilege_escalation = false
        #     privileged                 = false
        #     read_only_root_filesystem  = false
        #   }

        #   resources {
        #     limits = {
        #       cpu               = "2"
        #       memory            = "4Gi"
        #     }
        #     requests = {
        #       cpu               = "2"
        #       memory            = "4Gi"
        #     }
        #   }

        #   volume_mount {
        #     name       = "home"
        #     mount_path = "${local.home_folder}"
        #     read_only  = false
        #   }

        #   dynamic "env" {
        #     for_each = { CODER_AGENT_TOKEN = try(coder_agent.main-agent.token, "") }
        #     content {
        #       name  = env.key
        #       value = env.value
        #     }
        #   }
        # }

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.home.metadata[0].name
            read_only  = false
          }
        }

        affinity {
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

resource "kubernetes_persistent_volume_claim_v1" "home" {
  metadata {
    name      = "${local.ws_name}-home"
    namespace = var.namespace
    labels      = local.labels
    annotations = local.annotations
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "25Gi"
      }
    }
  }
}