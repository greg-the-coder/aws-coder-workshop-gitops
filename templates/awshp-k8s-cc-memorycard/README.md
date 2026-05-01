---
display_name: Memory Card Game with Vite
description: Memory Card Game with Vite
maintainer_github: jatcod3r
verified: false
tags: [kubernetes, container, ai, tasks]
---

# Work on a Memory Card Game!

This is an example app cloned from [coder-contrib/memory-card-ai-demo](https://github.com/coder-contrib/memory-card-ai-demo), deployed on Kubernetes with AI-powered development assistance. We include:

- [Anthropic - Claude Code](https://www.claude.com/product/claude-code) as the AI agent
- [Coder - AI Tasks](https://coder.com/docs/ai-coder/tasks) for task-based AI workflows
- [Coder - AI Bridge](https://coder.com/docs/ai-coder/ai-bridge) for model routing
- [Coder - Agent Boundary](https://coder.com/docs/ai-coder/agent-boundary) for network security
- [Coder - MUX](https://registry.coder.com/modules/coder/mux) for AI task management

Try prompts such as:

- "Change the card back design to a red diamond"
- "Add an option to choose difficulty levels (4x4, 6x6, 8x8 grids)"
- "Create theme selector"

## Template architecture

This template deploys a Kubernetes pod with:

- A **single Coder agent** (`coder_agent.main`) running in a container based on `coder-aienv:1.1.5`
- An **init container** that seeds the home directory from a Kubernetes ConfigMap with pre-configured dotfiles
- A **25GB persistent volume** for workspace storage
- Resource limits of **2 CPU / 4GB RAM**

### Apps and modules

| App / Module | Description |
|---|---|
| **AI Agent** | Claude Code running behind Agent Boundary with MCP servers (GitHub, Playwright) |
| **Preview App** | Vite dev server on port 5173 with health checks |
| **VS Code Web** | Browser-based VS Code with Prettier extension |
| **VS Code Desktop** | Native VS Code via SSH |
| **File Browser** | Web-based file manager |
| **Portable Desktop** | Full desktop environment in the browser |
| **Coder MUX** | AI proxy for task management (optional, togglable) |

### Home directory seeding

Configuration files are stored in the `home/` directory and mounted into the workspace via a Kubernetes ConfigMap. Templated files (e.g. `.claude/settings.json`, `.mux/providers.jsonc`) are rendered with workspace-specific values at deploy time. Per-file permissions are supported via `home_files_mode_overrides` in `workspace.tf`.

### Workspace parameters

| Parameter | Description | Default |
|---|---|---|
| `select_ai` | AI companion selector | `claude-code` |
| `preview_port` | Port for the Vite dev server | `5173` |
| `use_bots_git_creds` | Use coder-contrib bot Git credentials | `true` |
| `enable_mux` | Toggle Coder MUX on/off | `true` |

A [Workspace Preset](https://coder.com/docs/admin/templates/extending-templates/parameters#workspace-presets) named **"Ohio"** pre-configures the preview port and enables bot Git credentials.

### Prerequisites

- A Coder deployment (see [install docs](https://coder.com/docs/install)) with a connected Kubernetes cluster
- [AI Bridge](https://coder.com/docs/ai-coder/ai-bridge) configured with access to Anthropic models (Claude Opus 4.5, Claude Sonnet 4.5, Claude Haiku 4.5)
- GitHub external auth configured with ID `primary-github` (optional, for user-owned Git credentials)
- Template variables set: `gh_token`, `gh_username`, `gh_email`, `namespace`

### Pushing the template

Use the Coder CLI to push the template:

```sh
# Download the CLI
curl -L https://coder.com/install.sh | sh

# Log in to your deployment
coder login https://coder.example.com

# Navigate to this template directory
cd templates/deployments/ai.coder.com/coder/memorycard

# Push the template
coder templates push
```
