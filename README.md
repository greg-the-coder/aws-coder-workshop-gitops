# AWS Coder Workshop GitOps

AWS Workshop demonstration of GitOps workflows for Coder template administration, featuring AI-powered development environments and specialized templates for AWS cloud development.

## Overview

A comprehensive demonstration project showcasing GitOps workflows and best practices for Coder administration. This repository provides Infrastructure as Code (IaC) for deploying and managing Coder templates using Terraform, along with specialized workspace templates for various AWS development scenarios.

This repo is designed to be used with the [Kubernetes Devcontainer template](https://registry.coder.com/templates/kubernetes-devcontainer), which creates a Coder Workspace that Coder Admins can use for deployment and template administration. The [.devcontainer specification](./.devcontainer/) provisions a workspace with terraform, helm, and kubectl utilities commonly used by Platform Engineering teams.

## Prerequisites

- **Coder 2.x deployment** on Kubernetes
- **Coder Admin User** access
- **[Kubernetes Devcontainer template](https://registry.coder.com/templates/kubernetes-devcontainer)** installed
- **AWS Account** with appropriate permissions (for AWS-based templates)
- **AWS Bedrock** access for Claude Code templates

## Setup Instructions

1. **Fork or Clone**: Copy this repository to your own Git account
2. **Create Workspace**: Deploy a workspace from the Kubernetes Devcontainer template
3. **Configure Repository**: Use your forked/cloned repo URL for the Repository parameter
4. **Initialize Environment**: Follow the GitOps workflow instructions below

## GitOps Workflow

The GitOps workflow uses Terraform IaC, the Coder CLI, and automation scripts:

### Key Files
- **[template_versions.tf](./templates/template_versions.tf)**: Coder template resource definitions
- **[templates/](./templates/)**: Directory containing template source code
- **[templates_gitops.sh](./templates/templates_gitops.sh)**: Automation script for template deployment

### Workflow Steps

1. **Navigate to templates directory**:
   ```bash
   cd templates
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Authenticate with Coder**:
   ```bash
   coder login $CODER_AGENT_URL
   ```

4. **Deploy templates**:
   ```bash
   ./templates_gitops.sh <Coder Session Token>
   ```

This workflow enables version-controlled template management with automated deployment and updates.

## Coder Templates

Five specialized workspace templates for AWS development scenarios:

### 1. [Kubernetes with Claude Code](templates/awshp-k8s-with-claude-code/)
**AI-powered cloud-native development with task automation**

- **Claude Code 4.7.1** with AWS Bedrock (Claude Opus 4.5)
- **Task-based workflows** using `coder task create`
- **Pre-installed tools**: AWS CLI, AWS CDK, Node.js 20.x
- **Preview server** on port 3000 with health checks
- **Persistent storage**: 30GB default, tools persist across restarts
- **Use case**: General-purpose AI-assisted development

**Quick Start**:
```bash
coder task create --template "awshp-k8s-with-claude-code" \
  "Build a React todo app with TypeScript"
```

### 2. [Kubernetes RAG with Claude Code](templates/awshp-k8s-rag-with-claude-code/)
**RAG application prototyping with vector database**

- **Aurora PostgreSQL 16.8** Serverless v2 with pgvector extension
- **Claude Code 4.7.1** with AWS Bedrock (Claude Sonnet 4.5)
- **Streamlit preview** on port 8501
- **Auto-configured database**: Environment variables pre-set
- **Git integration**: Auto-clone RAG prototyping repository
- **Use case**: Building RAG applications with vector embeddings

**Features**:
- Vector similarity search with pgvector
- Automatic Python environment setup
- Database credentials via environment variables
- Streamlit app automation

### 3. [Kubernetes with Kiro CLI](templates/awshp-k8s-with-kiro-cli/)
**AI development assistant with MCP server support**

- **Kiro CLI** with web UI and command-line access
- **MCP Servers**: Pulumi, LaunchDarkly, Arize Tracing
- **AWS Development**: CLI v2 and CDK pre-installed
- **Workspace trust**: Auto-configured for seamless IDE integration
- **Persistent tools**: All installations survive restarts
- **Use case**: AI-assisted development with infrastructure tooling

**MCP Servers**:
- Pulumi: Infrastructure queries and management
- LaunchDarkly: Feature flag operations
- Arize: Tracing and observability

### 4. [Linux SAM](templates/awshp-linux-sam/)
**Serverless development with AWS SAM CLI**

- **AWS SAM CLI** for Lambda development
- **ARM64 optimization** (Graviton instances)
- **Python 3** runtime environment
- **Local testing**: API Gateway and Lambda simulation
- **EC2-based**: Fully persistent VM workspace
- **Use case**: Serverless application development and testing

**Instance Types**: m7g.medium, m7g.large (ARM64)

### 5. [Windows DCV](templates/awshp-windows-dcv/)
**Windows development with remote desktop**

- **NICE DCV** remote desktop with web access
- **Windows Server 2022** with full development capabilities
- **VS Code integration** for Windows
- **Multi-region support**: 15 AWS regions
- **Hardware acceleration**: GPU support when available
- **Use case**: Windows-specific development and GUI applications

**Access**: Web-based DCV client with port forwarding

## Template Comparison

| Template | Platform | AI Assistant | Database | Primary Use Case |
|----------|----------|--------------|----------|------------------|
| K8s Claude Code | Kubernetes | Claude Code 4.7.1 | - | General AI development |
| K8s RAG Claude | Kubernetes | Claude Code 4.7.1 | Aurora pgvector | RAG applications |
| K8s Kiro CLI | Kubernetes | Kiro CLI + MCP | - | Infrastructure + AI |
| Linux SAM | EC2 ARM64 | - | - | Serverless development |
| Windows DCV | EC2 x86 | - | - | Windows applications |

## Workshop Content

### 📚 [AI-Driven Development Workflows](workshop/README.md)

Comprehensive workshop content from the AWS Modernization with Coder workshop:

- **AI-powered development** with Amazon Q Developer and Claude Code
- **Hands-on exercises** for AI-assisted feature development
- **Task automation workflows** and best practices
- **Real-world scenarios** for cloud-native development

## Features

### GitOps Best Practices
- **Version Control**: All templates tracked in Git
- **Infrastructure as Code**: Terraform-based template definitions
- **Automated Deployment**: Script-based template updates
- **Change Management**: Git workflow for template modifications

### Platform Engineering
- **Kubernetes Devcontainer**: Pre-configured admin workspace
- **Tool Provisioning**: terraform, helm, kubectl pre-installed
- **Coder CLI Integration**: Automated template management
- **Multi-template Support**: Manage multiple templates from one repo

### AI-Powered Development
- **Claude Code Integration**: Latest AI assistant (4.7.1)
- **Task-Based Workflows**: Create workspaces with AI prompts
- **AWS Bedrock**: Enterprise-grade AI model access
- **MCP Server Support**: Extensible AI capabilities

### AWS Integration
- **Multi-Service Support**: EC2, EKS, Aurora, Bedrock
- **IAM Integration**: ServiceAccount-based permissions
- **Regional Deployment**: Multi-region template support
- **Cost Optimization**: Serverless and ARM64 options

## Architecture Patterns

### Kubernetes Templates
- **Ephemeral Pods**: Recreated on restart
- **Persistent Storage**: PVC for home directory
- **Service Accounts**: IAM role binding for AWS access
- **Resource Limits**: Configurable CPU/memory

### EC2 Templates
- **Persistent VMs**: Full filesystem persistence
- **Instance State Management**: Start/stop via Coder
- **IAM Instance Profiles**: AWS service access
- **Multi-region Support**: Deploy across AWS regions

## Additional Resources

- **[Coder Template Registry](https://registry.coder.com/templates)**: More template examples
- **[Coder Documentation](https://coder.com/docs)**: Platform documentation
- **[AWS Bedrock](https://aws.amazon.com/bedrock/)**: AI model information
- **[Terraform Coder Provider](https://registry.terraform.io/providers/coder/coder/latest/docs)**: Provider documentation

## Contributing

This repository demonstrates GitOps workflows for Coder templates. To contribute:

1. Fork the repository
2. Create a feature branch
3. Make template modifications
4. Test using the GitOps workflow
5. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- **Coder Support**: [coder.com/support](https://coder.com/support)
- **GitHub Issues**: Use this repository's issue tracker
- **Workshop Content**: See [workshop/README.md](workshop/README.md)

