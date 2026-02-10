---
display_name: AWS Workshop - EC2 (Linux) Kiro AI
description: Provision AWS EC2 VMs with Kiro AI IDE, AWS development tools, and MCP server support as Coder workspaces
icon: ../../../site/static/icon/aws.svg
maintainer_github: coder
verified: true
tags: [vm, linux, aws, persistent-vm, kiro, ai-ide, aws-cli, cdk, mcp]
---

# Remote Development on AWS EC2 VMs (Linux) with Kiro AI

Provision AWS EC2 VMs with integrated Kiro AI IDE, AWS CLI, AWS CDK, and Model Context Protocol (MCP) server support as [Coder workspaces](https://coder.com/docs/workspaces) with this workshop template.

## Prerequisites

### Infrastructure

**AWS Account**: This template requires an AWS account with appropriate permissions for EC2 instance management

**IAM Instance Profile**: This template uses a configurable IAM instance profile for AWS service access

### Authentication

This template authenticates to AWS using the provider's default [authentication methods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

To use another [authentication method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication), edit the template.

### Kiro AI IDE Integration

This template includes Kiro AI IDE integration that provides:
- AI-powered code generation and assistance with multiple model support
- Natural language to code conversion
- AWS service integration and best practices
- Interactive development workflows
- Model Context Protocol (MCP) server support for extensible AI capabilities
- Built-in workspace trust configuration for seamless development

## Required permissions / policy

The following sample policy allows Coder to create EC2 instances and modify
instances provisioned by Coder:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"ec2:GetDefaultCreditSpecification",
				"ec2:DescribeIamInstanceProfileAssociations",
				"ec2:DescribeTags",
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceTypes",
				"ec2:CreateTags",
				"ec2:RunInstances",
				"ec2:DescribeInstanceCreditSpecifications",
				"ec2:DescribeImages",
				"ec2:ModifyDefaultCreditSpecification",
				"ec2:DescribeVolumes"
			],
			"Resource": "*"
		},
		{
			"Sid": "CoderResources",
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeInstanceAttribute",
				"ec2:UnmonitorInstances",
				"ec2:TerminateInstances",
				"ec2:StartInstances",
				"ec2:StopInstances",
				"ec2:DeleteTags",
				"ec2:MonitorInstances",
				"ec2:CreateTags",
				"ec2:RunInstances",
				"ec2:ModifyInstanceAttribute",
				"ec2:ModifyInstanceCreditSpecification"
			],
			"Resource": "arn:aws:ec2:*:*:instance/*",
			"Condition": {
				"StringEquals": {
					"aws:ResourceTag/Coder_Provisioned": "true"
				}
			}
		}
	]
}
```

## Architecture

This template provisions the following resources:

- AWS EC2 Instance (Ubuntu 20.04 LTS)
- IAM instance profile for AWS service access
- Cloud-init configuration for automated setup
- Persistent EBS root volume
- Persistent home directory for tools and configurations

Coder uses `aws_ec2_instance_state` to start and stop the VM. This template is fully persistent, meaning the full filesystem is preserved when the workspace restarts. All development tools are installed to persistent locations in the user's home directory.

## Features

- **Kiro AI IDE**: AI-powered IDE with multi-model support and MCP integration
- **VS Code Web**: Access VS Code through the browser via code-server
- **Kiro CLI**: Command-line interface for Kiro AI capabilities
- **AWS CLI v2**: Pre-installed and configured AWS command line interface
- **AWS CDK**: Cloud Development Kit with Node.js 20 LTS runtime
- **MCP Server Support**: uv/uvx package manager for Model Context Protocol servers
- **Multi-Region Support**: Deploy in various AWS regions
- **Configurable Resources**: Choose instance type and disk size
- **Real-time Monitoring**: CPU, memory, and disk usage metrics
- **Persistent Installation**: All tools installed to home directory for persistence across restarts

## Parameters

- **Region**: AWS region for deployment (10 regions available)
- **Instance Type**: EC2 instance type (t3.micro to t3.large)
- **Root Volume Size**: EBS root volume size in GB (minimum 1 GB, expandable)
- **AWS IAM Profile**: IAM instance profile for AWS service access

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.

## Development Tools

### Kiro AI IDE
Kiro AI IDE is installed via the Coder registry module and provides:
- Multi-model AI assistance (Claude, GPT-4, and more)
- Integrated chat and code generation
- Model Context Protocol (MCP) server support
- Workspace trust pre-configured for seamless development
- Built-in terminal and debugging capabilities

### Code Server
`code-server` is installed via the Coder registry module and provides traditional VS Code access through the browser.

### Kiro CLI
The Kiro CLI is automatically installed to `~/.local/bin` and provides:
- Command-line access to Kiro AI capabilities
- MCP server configuration and management
- Integration with development workflows

### AWS Development Stack
- **AWS CLI v2**: Latest version installed to `~/.local/bin` with full AWS service support
- **AWS CDK**: Infrastructure as Code with TypeScript/JavaScript, installed globally via npm
- **Node.js 20 LTS**: Runtime for CDK, MCP servers, and modern JavaScript development
- **uv/uvx**: Python package manager for running MCP servers

### MCP Server Support
The template includes `uv` and `uvx` for running Model Context Protocol servers:
- Pre-configured MCP settings directory at `~/.kiro/settings/`
- Ready for MCP server integration (e.g., AWS documentation, filesystem access)
- Extensible architecture for custom MCP servers

## Getting Started

1. Create a workspace using this template
2. Access Kiro AI IDE through the Coder dashboard (primary interface)
3. Alternatively, access traditional VS Code via code-server
4. Start developing with AI assistance directly in Kiro IDE
5. Use `kiro-cli version` in the terminal to verify CLI installation
6. Configure MCP servers in `~/.kiro/settings/mcp.json` for extended capabilities

## Tool Installation Locations

All tools are installed to persistent locations in the home directory:

- **AWS CLI**: `~/.local/bin/aws`
- **AWS CDK**: `~/.npm-global/bin/cdk` (symlinked to `~/.local/bin/cdk`)
- **Kiro CLI**: `~/.local/bin/kiro-cli`
- **uv/uvx**: `~/.local/bin/uv` and `~/.local/bin/uvx`
- **Node.js**: System-wide installation via apt
- **npm global packages**: `~/.npm-global/`

The `PATH` is automatically configured to include these directories, ensuring all tools are available across workspace restarts.

## Workspace Trust Configuration

The template automatically configures Kiro IDE workspace trust settings:
- Workspace trust is enabled but startup prompts are disabled
- The home folder (`/home/coder`) is pre-trusted
- Untrusted files open without prompts for seamless development
- Configuration stored in `~/.kiro/settings/trusted-workspaces.json`
