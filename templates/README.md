# AWS Coder Workshop Templates

This directory contains Coder workspace templates designed for AWS development workflows and workshop scenarios. Each template provides a specialized development environment with pre-configured tools and services.

## Template Overview

### ☸️ [Kubernetes with Kiro CLI](awshp-k8s-with-kiro-cli/)
**Purpose**: AI-powered development with Kiro CLI and MCP server support  
**Architecture**: Kubernetes pods with persistent volumes  
**Key Tools**: Kiro CLI, AWS CLI v2, AWS CDK, Node.js 20 LTS, uv/uvx for MCP servers  
**Best For**: AI-assisted development, infrastructure as code, MCP server integration

### 🚀 [AWS Workshop - EC2 (Linux) SAM](awshp-linux-sam/)
**Purpose**: Serverless application development  
**Architecture**: Ubuntu ARM64 on Graviton EC2 instances  
**Key Tools**: AWS SAM CLI, AWS CLI v2, Python 3, Kiro extension  
**Best For**: Lambda functions, serverless APIs, cost-effective ARM64 development

### 🪟 [AWS Workshop - EC2 (Windows) DCV](awshp-windows-dcv/)
**Purpose**: Windows development with remote desktop  
**Architecture**: Windows Server 2022 on x86_64 EC2 instances  
**Key Tools**: NICE DCV, VS Code, PowerShell, Windows development stack  
**Best For**: Windows-specific development, GUI applications, .NET development

### ☸️ [Kubernetes with Claude Code](awshp-k8s-with-claude-code/)
**Purpose**: Container development with AI task automation  
**Architecture**: Kubernetes pods with persistent volumes  
**Key Tools**: Claude Code 4.7.1, AWS Bedrock, AWS CLI, AWS CDK, Node.js  
**Best For**: AI-driven development, task automation, microservices, container orchestration

### 🤖 [RAG with Claude Code](awshp-k8s-rag-with-claude-code/)
**Purpose**: RAG application prototyping with vector database  
**Architecture**: Kubernetes pods with Aurora PostgreSQL Serverless v2  
**Key Tools**: Claude Code, pgvector, AWS Bedrock, Streamlit, Python tooling  
**Best For**: AI/ML applications, vector search, RAG prototyping, data science

## Template Comparison

| Feature | K8s Kiro CLI | Linux SAM | Windows DCV | K8s Claude Code | RAG Claude Code |
|---------|------------------|-----------|-------------|-----------------|-----------------|
| **Platform** | Kubernetes | Ubuntu ARM64 | Windows Server | Kubernetes | Kubernetes |
| **AI Assistant** | Kiro CLI + MCP | Kiro Extension | - | Claude Code | Claude Code |
| **Primary Use** | General AWS Dev | Serverless | Windows Dev | Container Dev | RAG/AI Dev |
| **Cost Efficiency** | Variable | High (ARM64) | Higher | Variable | Variable |
| **Persistence** | Home directory | Full VM | Full VM | Home directory | Home directory |
| **Startup Time** | ~30-60 sec | ~2-3 min | ~5-10 min | ~30-60 sec | ~5-10 min |

## Getting Started

### Prerequisites
- Coder deployment with AWS provider configured
- AWS account with appropriate IAM permissions
- For Kubernetes templates: Existing Kubernetes cluster

### Template Selection Guide

**Choose Kubernetes with Kiro CLI if you want:**
- AI-powered development assistance with MCP server support
- Infrastructure as Code with CDK
- General-purpose AWS development on Kubernetes
- Fast workspace startup times
- Configurable MCP servers 

**Choose Linux SAM if you want:**
- Serverless application development
- Cost-effective ARM64 instances
- Lambda function development
- Local serverless testing

**Choose Windows DCV if you want:**
- Windows-specific development
- GUI application development
- .NET or Windows-only tools
- Remote desktop experience

**Choose Kubernetes Claude Code if you want:**
- Container-based development
- AI task automation with Claude Code
- Microservices architecture
- Fast workspace startup times

**Choose RAG Claude Code if you want:**
- RAG application development
- Vector database integration
- AI/ML prototyping with Bedrock
- Streamlit-based data applications

## Configuration

### IAM Instance Profile
EC2-based templates (Linux SAM, Windows DCV) require an IAM instance profile for AWS service access. Configure the `aws_iam_profile` variable when deploying templates.

### Kubernetes Service Account
Kubernetes-based templates use ServiceAccount with IAM role binding for AWS service access.

### Regional Deployment
All templates support multi-region deployment with region-specific optimizations:
- **Kubernetes Kiro CLI**: Depends on cluster location
- **Linux SAM**: 4 US regions (ARM64 availability)
- **Windows DCV**: 15 regions globally
- **Kubernetes Claude Code**: Depends on cluster location
- **RAG Claude Code**: Depends on cluster location + Aurora availability

### Resource Sizing
Each template offers configurable resource options:
- **CPU**: 2-8 vCPUs depending on template
- **Memory**: 4-16 GiB RAM options
- **Storage**: 10-50 GB persistent volumes (Kubernetes) or 10-300 GB (EC2)
- **Database**: Aurora Serverless v2 (0.5-1.0 ACU for RAG template)

## Workshop Integration

These templates are designed for the AWS Modernization with Coder workshop and include:
- Pre-configured development environments
- Workshop-specific tooling and dependencies
- Optimized resource configurations
- Integration with workshop exercises

## Support and Customization

Each template is designed as a starting point and can be customized for specific use cases:
- Modify Terraform configurations for additional AWS services
- Extend startup scripts for custom tool installation
- Adjust resource parameters for performance requirements
- Add custom applications and integrations

> **Note**: These templates are designed for workshop and development use. For production deployments, review and adjust security configurations, resource limits, and access controls according to your organization's requirements.