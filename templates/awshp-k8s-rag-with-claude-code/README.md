---
display_name: Kubernetes RAG with Claude Code
description: RAG application prototyping with Aurora PostgreSQL pgvector and Claude Code AI assistant
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [kubernetes, container, ai, claude, aws-bedrock, rag, postgresql, pgvector, aurora]
---

# AWS RAG Application Prototyping with Claude Code

A comprehensive Kubernetes-based Coder template for building Retrieval-Augmented Generation (RAG) applications with integrated Aurora PostgreSQL pgvector database and Claude Code AI assistant.

## Prerequisites

### Infrastructure

**Kubernetes Cluster**: Requires an existing EKS cluster with Coder deployed

**AWS Services**: 
- Aurora PostgreSQL Serverless v2 with pgvector extension
- AWS Bedrock with Claude model access
- VPC with private subnets for Aurora deployment

**Container Image**: Uses [codercom/enterprise-base:ubuntu image](https://github.com/coder/enterprise-images/tree/main/images/base)

### Authentication

- **Kubernetes**: Authenticates via `~/.kube/config` or ServiceAccount
- **AWS**: Requires IAM permissions for Aurora, Bedrock, and EKS services

### Claude Code Integration

This template includes Claude Code 4.7.1 with AWS Bedrock integration:
- AI-powered RAG application development
- Task-based automation using `coder task create`
- AWS Bedrock Claude Sonnet 4.5 model (configurable)
- Automatic database setup and vector extension enablement
- Streamlit application preview on port 8501

## Architecture

### Kubernetes Resources
- **Deployment**: Ephemeral pod with Coder agent
- **Persistent Volume Claim**: 30GB default for `/home/coder`
- **Service Account**: Named `coder` with AWS IAM role binding

### Database Infrastructure
- **Aurora PostgreSQL 16.8**: Serverless v2 cluster
- **pgvector Extension**: Automatically enabled for vector embeddings
- **Scaling**: 0.5-1.0 ACU (configurable)
- **Networking**: Deployed in private subnets with security group
- **Backup**: 7-day retention period

### Development Tools
Pre-installed and persisted in home directory:
- **AWS CLI v2**: Installed to `~/.local/aws-cli`
- **AWS CDK**: Installed to `~/.npm-global`
- **Node.js 20.x LTS**: System-wide installation
- **PostgreSQL Client**: For database management
- **uv/uvx**: Python package manager for MCP servers
- **Telnet**: Network diagnostics

## Features

### AI-Powered Development
- **Claude Code 4.7.1**: Latest AI assistant with task automation
- **AWS Bedrock**: Claude Sonnet 4.5 model (default)
- **Task Management**: Create RAG tasks via `coder task create`
- **Automated Setup**: Python environment and dependency installation
- **Background Processes**: Desktop Commander for Streamlit apps

### Database Integration
- **pgvector**: Vector similarity search for embeddings
- **Auto-Configuration**: Database credentials via environment variables
- **Connection Details**: Pre-configured in workspace environment
  - `PGVECTOR_HOST`: Aurora endpoint
  - `PGVECTOR_DATABASE`: mydb1
  - `PGVECTOR_USER`: dbadmin
  - `PGVECTOR_PASSWORD`: Configurable
  - `PGVECTOR_PORT`: 5432

### Development Environment
- **code-server**: VS Code in the browser
- **Kiro**: AI-powered code editor
- **Git Clone**: Automatic repository cloning (default: aws-rag-prototyping)
- **Streamlit Preview**: Port 8501 with health checks
- **Web Terminal**: Direct browser access

## Parameters

### Compute Resources
- **CPU cores**: 4-8 cores (default: 4)
- **Memory**: 4-16 GB (default: 4 GB)
- **PVC storage size**: 10-50 GB (default: 30 GB)

### Configuration Variables
- **EKS Cluster Name**: Default `coder-eks-cluster`
- **Namespace**: Default `coder`
- **Anthropic Model**: Claude Sonnet 4.5 (configurable)
- **Anthropic Small Fast Model**: Claude Haiku 4.5 (configurable)
- **PostgreSQL Version**: 16.8 (configurable)
- **Git Repository**: Default aws-rag-prototyping repo

## Usage

### Creating a RAG Development Workspace

Use the task-based approach for AI-assisted development:

```bash
coder task create --template "awshp-k8s-rag-with-claude-code" \
  "Build a RAG chatbot using the pgvector database for document embeddings"
```

Claude Code will automatically:
1. Clone the specified Git repository
2. Create a Python virtual environment
3. Install dependencies from requirements.txt
4. Start the Streamlit application
5. Report the preview URL to Coder

### Default Task Behavior

The default task prompt:
> "Look for an AWS RAG Prototyping repo in the Coder Workspace. If found, create a new Python3 virtual environment, pip install the requirements.txt and then start the app via streamlit."

### Database Access

Connect to Aurora PostgreSQL from within the workspace:

```bash
psql -h $PGVECTOR_HOST -U $PGVECTOR_USER -d $PGVECTOR_DATABASE
```

The pgvector extension is automatically enabled during workspace creation.

### RAG Development Workflow

1. **Vector Storage**: Use pgvector for document embeddings
2. **Development**: Build RAG applications with Python/Streamlit
3. **Testing**: Preview on port 8501 with automatic health checks
4. **AI Assistance**: Claude Code helps with implementation
5. **Deployment**: Use AWS CDK for infrastructure deployment

## Database Configuration

### Aurora PostgreSQL Details
- **Engine**: PostgreSQL 16.8
- **Deployment**: Serverless v2 with auto-scaling
- **Capacity**: 0.5-1.0 ACU
- **Storage**: Auto-scaling enabled
- **Backup**: 7-day retention
- **Extensions**: pgvector pre-enabled

### Security
- **Network**: Private subnets only
- **Security Group**: PostgreSQL port 5432
- **Credentials**: Managed via local variables
- **Encryption**: At-rest and in-transit

## System Prompt Capabilities

Claude Code is configured for RAG development:
- Streamlit application management on port 8501
- Python virtual environment setup
- Dependency installation and management
- Background process handling with Desktop Commander
- Automated testing with Playwright
- Task progress reporting to Coder

## Advanced Configuration

### Custom Models

Configure different Claude models:

```hcl
variable "anthropic_model" {
  default = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
}

variable "anthropic_small_fast_model" {
  default = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
}
```

### Database Credentials

Update database configuration in locals:

```hcl
locals {
  db_username = "dbadmin"
  db_password = "YourStrongPasswordHere1"
  db_name     = "mydb1"
  db_port     = "5432"
}
```

### Custom Git Repository

Change the default repository:

```hcl
data "coder_parameter" "git_repo" {
  default = "https://github.com/your-org/your-rag-repo.git"
}
```

## Cost Considerations

- **Aurora Serverless v2**: Scales to zero when not in use (0.5 ACU minimum)
- **Kubernetes**: Pod resources scale based on parameters
- **Storage**: PVC persists and incurs storage costs
- **Bedrock**: Pay-per-token for Claude model usage

## Troubleshooting

### Database Connection Issues
```bash
# Test connectivity
telnet $PGVECTOR_HOST 5432

# Check environment variables
env | grep PGVECTOR
```

### Vector Extension
```sql
-- Verify pgvector is enabled
SELECT * FROM pg_extension WHERE extname = 'vector';
```

### Streamlit App
```bash
# Check if app is running
curl http://localhost:8501

# View logs
ps aux | grep streamlit
```

## Notes

- First startup takes 5-10 minutes for Aurora cluster creation
- Tools persist in home directory across restarts
- Aurora cluster is workspace-specific (created per workspace)
- Task-based creation is recommended for AI-assisted development
- Preview URLs automatically proxy through Coder

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.