# AI-Driven Development

## Speed Up Development with Intelligent Automation

AI-driven development workflows represent a fundamental shift from reactive to proactive development. Instead of waiting for issues to arise, AI anticipates needs, suggests optimizations, and automates routine tasks, allowing developers to focus on creative problem-solving and innovation.

### Setting Up Your AI Development Environment

Let's create your Coder workspace with comprehensive AI development tools.

#### Step 1: Access Your AI-Enhanced Workspace

Create a workspace using the AWS Workshop - Kubernetes with Kiro CLI template:
1. **Access your Coder dashboard** and click "Create Workspace"
2. **Select the AWS Workshop - Kubernetes with Kiro CLI template** (created from the [template](../../templates/awshp-k8s-with-kiro-cli/README.md) in this repo)
3. **Configure the workspace parameters**:
   - **Name**: `kiro-cli-workspace`
   - **Instance type**: 2 vCPU, 4 GiB RAM
   - **Region**: us-east-1 (Default)
   - **Disk Size**: 30 GB (Default)

4. **Click "Create Workspace"** and wait for it to start

> **ℹ️ Info**: The selected Coder workspace template will automatically provision the AWS CLI, CDK, Amazon Kiro CLI and other tools needed for AI-Driven AWS Development.

#### Step 2: Access Your Linux Kiro Workspace

Once your workspace is running:

1. **Open the workspace** from your Coder dashboard
2. **Launch code-server** or your preferred editor
3. **Open a terminal** within the workspace

#### Step 3: Initialize Workshop Git/Github repo
Once in your workspace, let's create a workshop directory and initialize a git repo:
```bash
mkdir ai-dev-workflows 
```
Now from code-server or VS Code:

1. **Use File/Open Folder** to open the workshop directory
2. **Use Git extension** to initialize a git repository in the current directory

#### Step 4: Initialize AI Development Tools
Back in your workspace terminal session, let's set up the AI development environment:
```bash
# Initialize the Kiro CLI
kiro-cli login    # Use for Free with Builder ID option, and follow prompts
kiro-cli chat     # Initialize chat session
```

### Workflow 1: AI-Assisted Feature Development
#### Scenario: Create a simple Cloud-Native Task Management Web App
Let's walk through developing a new feature using AI assistance from start to finish.

Step 1: Requirements Analysis with AI, start by describing your feature in natural language:
```bash
# Use Amazon Kiro to analyze requirements with the following prompt:
analyze the following requirements: "Create a simple task management web app that tracks task id, description, priority, and completion date.  Provide two ways to interact with the data, one that summarizes open tasks by priority and another lists completed tasks by date"
```
Amazon Kiro will provide:
- Technical requirements breakdown
- Architecture suggestions
- Implementation approach
- Potential challenges and solutions

Step 2: AI-Generated Project Structure
```bash
# Next, have Amazon Kiro generate the supporting project structure with the following prompt:
generate a supporting project structure for an AWS CDK application that uses typscript for the front end components and python for back-end API components
```

> **ℹ️ Info**: Notice how Amazon Kiro always prompts you to "trust" it when creating or updating content in your Coder workspace.

This should create something similar to this:
```bash
task-management-app/
├── infrastructure/          # AWS CDK TypeScript code
│   ├── bin/app.ts          # CDK app entry point
│   ├── lib/                # CDK stack definitions
│   │   ├── database-stack.ts    # DynamoDB table
│   │   ├── backend-stack.ts     # Lambda + API Gateway
│   │   └── frontend-stack.ts    # S3 + CloudFront
│   └── package.json        # CDK dependencies
├── backend/                # Python Lambda functions
│   ├── src/
│   │   ├── models/         # Data models
│   │   ├── services/       # Business logic
│   │   └── handlers/       # Lambda handlers
│   └── requirements.txt    # Python dependencies
├── frontend/               # React TypeScript app
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── services/       # API client
│   │   └── types/          # TypeScript interfaces
│   └── package.json        # React dependencies
└── scripts/                # Deployment scripts
```

Step 3: AI-Generated AWS Deployment
```bash
# Smoke-test deployment to AWS by having Amazon Kiro deploy the generated web app to the current AWS account with the following prompt:
Smoke test the web app deployment to the current AWS account using the created deployment scripts
```

> **ℹ️ Info**: Notice how Amazon Kiro will find and debug issues as it works with the existing scripts and workspace environment, installing required dependencies as needed.  Additionally, you will most likely see Amazon Kiro iterate across Lambda Functions, Back-End Schema, and other component issues as it tests the CDK stacks being deployed.

When completed, at least your Database and Backend stacks should be successfully deployed and smoke-tested.  You can continue to prompt Amazon Kiro to complete the full application deployment, if desired.  It is suggested you commit and push changes to your workshop Git repo at this point, as this Git repo will be used in the next AI-Driven Workflow example.

Step 4: Cleanup AI-Generated AWS Deployment
```bash
# Have Amazon Kiro safely remove any deployments created for smoke-testing from the current AWS account with the following prompt:
Remove any CDK stack deployments used for smoke-testing the task mananagement web app from the current AWS account.  Double-check that only task management stacks are being deleted and nothing else.
```
This should remove any deployed components and ensure Amazon Kiro double-checks and reviews what was deleted.  You can now end your Kiro CLI chat session with:
```bash
/quit
```

> **🚀 Workflow Optimization**: These AI development workflows can reduce development time by 60-80% while improving code quality. Start with one workflow and gradually add more as your team becomes comfortable.

## [Next Steps](ai-driven-automation.md)

Now that you've experimented with AI-Driven Development, you can now see how [AI-Driven Automation](ai-driven-automation.md) can support your development workflow.