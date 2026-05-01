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
  ws_img          = "public.ecr.aws/f7a1d7a4/coder-aienv:1.1.5"

  # Dynamic home directory file mounting
  home_base_path          = "${path.module}/home/coder"
  home_files_default_mode = "0666" # Read and write for all (user, group, others)

  # Per-file mode overrides (path relative to home/coder)
  home_files_mode_overrides = {
    ".local/bin/claude" = "0555" # Read-only + executable for all
    ".local/bin/random-port" = "0555" # Read-only + executable for all
    # Add more overrides as needed:
    # ".config/sensitive.conf" = "0600"
  }

  # Files that require templatefile() substitution with per-file template variables
  # Key: file path relative to home/coder
  # Value: map of template variables for that file
  home_files_templated = {
    ".claude/settings.json" = {
      work_folder  = local.work_folder
      user_name    = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
      user_email   = data.coder_workspace_owner.me.email
      gh_username  = local.gh_username
      gh_email     = local.gh_email
      gh_token     = local.gh_token
    }
    ".claude.json" = {
      home_folder = local.home_folder
    }
    ".mux/providers.jsonc" = {
      access_url    = data.coder_workspace.me.access_url
      session_token = data.coder_workspace_owner.me.session_token
    }
    ".mcp.json" = {
      gh_token = local.gh_token
    }
    "AGENTS.md" = {
      work_folder  = local.work_folder
      preview_port = local.preview_port
    }
  }

  home_files = fileset(local.home_base_path, "**")

  # Filter to only include files (not directories), include mode per file
  # Use templatefile() for templated files, file() for static files
  home_file_map = {
    for f in local.home_files : f => {
      content = contains(keys(local.home_files_templated), f) ? templatefile("${local.home_base_path}/${f}", local.home_files_templated[f]) : file("${local.home_base_path}/${f}")
      mode    = lookup(local.home_files_mode_overrides, f, local.home_files_default_mode)
    }
    if !can(file("${local.home_base_path}/${f}")) ? false : length(file("${local.home_base_path}/${f}")) >= 0
  }

  # Extract unique directories that need to be created
  home_dirs = toset([
    for f in keys(local.home_file_map) : dirname(f)
    if dirname(f) != "."
  ])
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

        init_container {
          name  = "seed-home"
          image = "busybox:latest"
          command = ["sh", "-c", <<-EOF
            set -e

            # Create all directories
            %{for dir in local.home_dirs~}
            mkdir -p "${local.home_folder}/${dir}"
            %{endfor~}

            # Copy all files and apply per-file permissions
            %{for path, file_info in local.home_file_map~}
            cp "/config/${replace(path, "/", "--")}" "${local.home_folder}/${path}"
            chmod ${file_info.mode} "${local.home_folder}/${path}"
            %{endfor~}

            # Set ownership
            chown -R 1000:1000 ${local.home_folder}
          EOF
          ]

          security_context {
            run_as_user = 0
          }

          volume_mount {
            name       = "home-config"
            mount_path = "/config"
            read_only  = true
          }

          volume_mount {
            name       = "home"
            mount_path = local.home_folder
            read_only  = false
          }
        }

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
          name = "home-config"
          config_map {
            name         = kubernetes_config_map_v1.home_files[0].metadata[0].name
            default_mode = local.home_files_default_mode
          }
        }

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

resource "kubernetes_config_map_v1" "home_files" {
  count = data.coder_workspace.me.start_count
  metadata {
    name        = "${local.ws_name}-home-files"
    namespace   = var.namespace
    labels      = local.labels
    annotations = local.annotations
  }

  data = {
    for path, file_info in local.home_file_map : replace(path, "/", "--") => file_info.content
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