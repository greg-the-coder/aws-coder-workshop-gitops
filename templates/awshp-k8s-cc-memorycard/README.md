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
- [Coder](https://coder.com/docs) for task-based AI workflows, model routing, and network security

Try prompts such as:

- "Change the card back design to a red diamond"
- "Add an option to choose difficulty levels (4x4, 6x6, 8x8 grids)"
- "Create theme selector"

## Template architecture

This template deploys a Kubernetes pod with:

- A **single Coder agent** (`coder_agent.main`) running in a container based on `coder-aienv:1.1.5`
- A **startup script** that seeds the home directory with pre-configured dotfiles and AI agent configuration
- A **25GB persistent volume** for workspace storage
- Resource limits of **2 CPU / 4GB RAM**

### Apps and modules

| App / Module | Description |
|---|---|
| **AI Agent** | Claude Code running in a tmux session with MCP servers (GitHub, Playwright) |
| **Preview App** | Vite dev server on port 5173 with health checks |
| **VS Code Web** | Browser-based VS Code with Prettier extension |
| **VS Code Desktop** | Native VS Code via SSH |
| **File Browser** | Web-based file manager |
| **Portable Desktop** | Full desktop environment in the browser |

### Home directory seeding

Configuration files are stored in the `home/` directory and seeded into the workspace via a startup script. Templated files (e.g. `.claude.json`, `.mcp.json`) are rendered with workspace-specific values at deploy time.

### Workspace parameters

| Parameter | Description | Default |
|---|---|---|
| `Preview Port` | Port for the Vite dev server | `5173` |
| `Use Bot's Git Credentials?` | Use coder-contrib bot Git credentials | `true` |



### Prerequisites

- A Coder deployment (see [install docs](https://coder.com/docs/install)) with a connected Kubernetes cluster
- Coder AI model routing configured with access to Anthropic models (Claude Opus 4.5, Claude Sonnet 4.5, Claude Haiku 4.5)
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
cd templates/awshp-k8s-cc-memorycard

# Push the template
coder templates push
```
