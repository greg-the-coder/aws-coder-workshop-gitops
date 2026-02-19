---
display_name: Kubernetes with Claude Code
description: Provision Kubernetes Deployments with Claude Code AI assistant as Coder workspaces
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [kubernetes, container, ai, claude, aws-bedrock]
---

# Remote Development on Kubernetes Pods with Claude Code

Provision Kubernetes Pods with integrated Claude Code AI assistant as [Coder workspaces](https://coder.com/docs/workspaces) with this template. Features AI-powered task automation using AWS Bedrock and Claude models.

## Prerequisites

### Infrastructure

**Cluster**: This template requires an existing Kubernetes cluster with Coder deployed

**Container Image**: This template uses the [codercom/enterprise-base:ubuntu image](https://github.com/coder/enterprise-images/tree/main/images/base) with development tools preinstalled

**AWS Bedrock Access**: Requires access to AWS Bedrock with Claude models enabled

### Authentication

This template authenticates using a `~/.kube/config`, if present on the server, or via built-in authentication if the Coder provisioner is running on Kubernetes with an authorized ServiceAccount. To use another [authentication method](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#authentication), edit the template.

### Claude Code Integration

This template includes Claude Code 4.7.1 with AWS Bedrock integration that provides:
- AI-powered code generation and development assistance
- Task-based automation using `coder task create` command
- Integration with AWS Bedrock for Claude Opus 4.5 model
- Automatic task reporting and status updates to Coder
- Desktop Commander for background process management
- Playwright integration for web application testing

## Architecture

This template provisions the following resources:

- **Kubernetes Deployment** (ephemeral, recreated on restart)
- **Persistent Volume Claim** (30GB default, persistent on `/home/coder`)
- **Coder Agent** with Claude Code integration
- **Development Tools**: AWS CLI, AWS CDK, Node.js 20.x, npm
- **AI Assistant**: Claude Code with task automation

When the workspace restarts, the pod is recreated but the home directory persists. Tools installed to `/home/coder/.local/bin` and `/home/coder/bin` are preserved across restarts.

## Features

### Development Environment
- **code-server**: VS Code in the browser with full extension support
- **Kiro**: AI-powered code editor integration
- **Web Terminal**: Direct terminal access through the browser
- **Preview App**: Built-in preview server on port 3000 with health checks

### AI Capabilities
- **Claude Code 4.7.1**: Latest AI assistant with task automation
- **AWS Bedrock**: Claude Opus 4.5 model integration
- **Task Management**: Create and manage AI tasks via `coder task create`
- **Automated Testing**: Playwright integration for web app validation
- **Background Processes**: Desktop Commander for long-running commands

### Pre-installed Tools
All tools are installed to persistent storage during first startup:
- **AWS CLI v2**: Installed to `~/.local/aws-cli`
- **AWS CDK**: Installed to `~/.npm-global`
- **Node.js 20.x LTS**: System-wide installation
- **uv/uvx**: Python package manager for MCP servers
- **Coder CLI**: Symlinked for task management

## Parameters

### Configurable Resources
- **CPU cores**: 2-8 cores (default: 4)
- **Memory**: 4-16 GB (default: 8 GB)
- **PVC storage size**: 10-50 GB (default: 30 GB)

### AI Configuration
- **Anthropic Model**: Configurable via variable (default: Claude Opus 4.5)
- **Task Prompt**: Provided via `coder task create` command

## Usage

### Creating a Task-Based Workspace

Instead of using traditional workspace creation, use the task-based approach:

```bash
coder task create --template "awshp-k8s-with-claude-code" "Build a React todo app with TypeScript"
```

This creates a workspace where Claude Code automatically:
1. Posts a 'task started' update to Coder
2. Reviews its memory and context
3. Executes the provided prompt
4. Reports progress and completion status

### Development Workflow

1. **Web Applications**: Claude Code automatically:
   - Starts dev servers on localhost:3000
   - Uses Desktop Commander for background processes
   - Tests with Playwright and takes screenshots
   - Reports preview URLs to Coder

2. **AWS Development**: Pre-configured with:
   - AWS CLI for service management
   - AWS CDK for infrastructure as code
   - Persistent tool installations

3. **Task Management**: 
   - View task status in Coder dashboard
   - Claude Code reports progress updates
   - Automatic error reporting and recovery

## System Prompt Capabilities

Claude Code is configured with specialized instructions for:
- Web application development with automatic server management
- Port management and conflict resolution
- Automated testing with Playwright
- Task reporting (under 160 characters)
- Template and workspace creation restrictions
- Preview URL generation

## Advanced Configuration

### Custom Models

Edit the `anthropic_model` variable to use different Claude models:

```hcl
variable "anthropic_model" {
  default = "global.anthropic.claude-opus-4-5-20251101-v1:0"
}
```

### MCP Server Integration

The template includes uv/uvx for MCP server support. Add custom MCP servers in the `post_install_script` section.

### Namespace Configuration

Default namespace is `coder`. Update the `namespace` variable for different deployments.

## Notes

- First startup takes longer due to tool installation
- Subsequent starts are faster as tools persist in home directory
- Claude Code requires AWS Bedrock access with appropriate IAM permissions
- Task-based workspaces are recommended over traditional workspace creation
- Preview apps automatically proxy through Coder's subdomain routing

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.
