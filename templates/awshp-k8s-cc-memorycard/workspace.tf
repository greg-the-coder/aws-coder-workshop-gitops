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
  home_base_path = "${path.module}/home/coder"

  # ── Home directory file seeding ──────────────────────────────────────
  # Files are written by coder_script.seed_home on first start.
  # Each entry: path relative to $HOME, content (optionally templated),
  # and octal mode string.
  #
  # To add a new file:
  #   1. Drop it into home/coder/<path>
  #   2. Add an entry below (use templatefile() if it needs variable substitution)
  #   3. Set the mode (0666 for regular files, 0555 for executables)

  home_seed_files = {
    # ── Templated files ──
    ".claude.json" = {
      content = templatefile("${local.home_base_path}/.claude.json", {
        home_folder = local.home_folder
      })
      mode = "0666"
    }
    ".mcp.json" = {
      content = templatefile("${local.home_base_path}/.mcp.json", {
        gh_token = local.gh_token
      })
      mode = "0666"
    }
    "AGENTS.md" = {
      content = templatefile("${local.home_base_path}/AGENTS.md", {
        work_folder  = local.work_folder
        preview_port = local.preview_port
      })
      mode = "0666"
    }
    ".mux/providers.jsonc" = {
      content = templatefile("${local.home_base_path}/.mux/providers.jsonc", {
        access_url    = data.coder_workspace.me.access_url
        session_token = data.coder_workspace_owner.me.session_token
      })
      mode = "0666"
    }

    # ── Static files ──
    ".mux/config.json" = {
      content = file("${local.home_base_path}/.mux/config.json")
      mode    = "0666"
    }
    ".mux/policy.json" = {
      content = file("${local.home_base_path}/.mux/policy.json")
      mode    = "0666"
    }
    ".config/coder_boundary/boundary-config.yaml" = {
      content = file("${local.home_base_path}/.config/coder_boundary/boundary-config.yaml")
      mode    = "0666"
    }
    ".vscode-server/data/Machine/settings.json" = {
      content = file("${local.home_base_path}/.vscode-server/data/Machine/settings.json")
      mode    = "0666"
    }

    # ── Executable scripts ──
    ".local/bin/claude" = {
      content = file("${local.home_base_path}/.local/bin/claude")
      mode    = "0555"
    }
    ".local/bin/random-port" = {
      content = file("${local.home_base_path}/.local/bin/random-port")
      mode    = "0555"
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