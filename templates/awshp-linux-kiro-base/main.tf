terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "aws_iam_profile" {
  type        = string
  default     = "coder-workshop-ec2-workspace-profile"
  description = "The AWS IAM Role to assign to the Coder EC2 Workspace for access to other AWS Accounts and Services"
}

# Last updated 2023-03-14
# aws ec2 describe-regions | jq -r '[.Regions[].RegionName] | sort'
data "coder_parameter" "region" {
  name         = "region"
  display_name = "Region"
  description  = "The region to deploy the workspace in."
  default      = "us-east-1"
  mutable      = false
  option {
    name  = "Asia Pacific (Singapore)"
    value = "ap-southeast-1"
    icon  = "/emojis/1f1f8-1f1ec.png"
  }
  option {
    name  = "Asia Pacific (Sydney)"
    value = "ap-southeast-2"
    icon  = "/emojis/1f1e6-1f1fa.png"
  }
  option {
    name  = "Canada (Central)"
    value = "ca-central-1"
    icon  = "/emojis/1f1e8-1f1e6.png"
  }
  option {
    name  = "EU (Ireland)"
    value = "eu-west-1"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (London)"
    value = "eu-west-2"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (Paris)"
    value = "eu-west-3"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "US East (N. Virginia)"
    value = "us-east-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US East (Ohio)"
    value = "us-east-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (N. California)"
    value = "us-west-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (Oregon)"
    value = "us-west-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
}

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance type"
  description  = "What instance type should your workspace use?"
  default      = "t3.micro"
  mutable      = false
  option {
    name  = "2 vCPU, 1 GiB RAM"
    value = "t3.micro"
  }
  option {
    name  = "2 vCPU, 2 GiB RAM"
    value = "t3.small"
  }
  option {
    name  = "2 vCPU, 4 GiB RAM"
    value = "t3.medium"
  }
  option {
    name  = "2 vCPU, 8 GiB RAM"
    value = "t3.large"
  }
}

data "coder_parameter" "root_volume_size_gb" {
  name         = "root_volume_size_gb"
  display_name = "Root Volume Size (GB)"
  description  = "How large should the root volume for the instance be?"
  default      = 30
  type         = "number"
  mutable      = true
  validation {
    min       = 1
    monotonic = "increasing"
  }
}

provider "aws" {
  region = data.coder_parameter.region.value
}

#### Update to Workshop IAM Instance Profile
data "aws_iam_instance_profile" "vm_instance_profile" {
   name  = var.aws_iam_profile
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

locals {
    home_folder = "/home/coder"
}

resource "coder_agent" "dev" {
  count          = data.coder_workspace.me.start_count
  arch           = "amd64"
  auth           = "aws-instance-identity"
  os             = "linux"
  startup_script = <<-EOT
    set -e
    set -e
    
    # Create persistent bin directory
    mkdir -p $HOME/bin
    mkdir -p $HOME/.local/bin
    
    # Update PATH for current session
    export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.npm-global/bin:$PATH"
    
    sudo apt update
    sudo apt install -y curl unzip gnupg dirmngr

    # install AWS CLI to persistent location
    if ! command -v aws &> /dev/null; then
      echo "Installing AWS CLI..."
      cd $HOME
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip -q awscliv2.zip
      
      # Install to home directory instead of system-wide
      ./aws/install --install-dir $HOME/.local/aws-cli --bin-dir $HOME/.local/bin
      
      # Verify installation
      aws --version
      
      # Cleanup
      rm -rf aws awscliv2.zip
      
      echo "AWS CLI installation completed"
    else
      echo "AWS CLI is already installed"
      aws --version
    fi

    # install Node.js and npm (required for CDK, LaunchDarkly MCP, and Kiro CLI)
    if ! command -v node &> /dev/null; then
      echo "Installing Node.js..."
      # Add NodeSource repository for the latest LTS version
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt-get install nodejs -y
      
      # Verify installation
      node -v
      npm -v
      
      echo "Node.js installation completed"
    else
      echo "Node.js is already installed"
      node -v
    fi

    # install AWS CDK to persistent location
    if ! command -v cdk &> /dev/null; then
      echo "Installing AWS CDK..."
      
      # Configure npm to use home directory for global packages
      mkdir -p $HOME/.npm-global
      npm config set prefix "$HOME/.npm-global"
      
      # Install AWS CDK to home directory
      npm install -g aws-cdk
      
      # Create symlink in bin directory
      ln -sf $HOME/.npm-global/bin/cdk $HOME/.local/bin/cdk
      
      # Verify CDK installation
      cdk --version
      
      echo "AWS CDK installation completed"
    else
      echo "AWS CDK is already installed"
      cdk --version
    fi

    # install Kiro CLI to persistent location
    if ! command -v kiro-cli &> /dev/null; then
      echo "Installing Kiro CLI..."
      curl -fsSL https://cli.kiro.dev/install | bash
      
      # Verify Kiro CLI installation
      kiro-cli version
      
      echo "Kiro CLI installation completed"
    else
      echo "Kiro CLI is already installed"
      kiro-cli version
    fi

    # Install uv (Python package manager) which includes uvx for MCP servers
    if [ ! -f "$HOME/.local/bin/uv" ]; then
      echo "Installing uv/uvx..."
      UV_UNMANAGED_INSTALL="$HOME/.local/bin" curl -LsSf https://astral.sh/uv/install.sh | sh
      echo "uv/uvx installation completed"
    else
      echo "uv/uvx is already installed"
    fi
    
    # Configure Kiro CLI MCP servers
    echo "Configuring Kiro CLI MCP servers..."
    mkdir -p $HOME/.kiro/settings
    
    # Create MCP configuration file here
    # cat > $HOME/.kiro/settings/mcp.json <<'MCP_EOF'
    # MCP_EOF
    
    echo "Kiro CLI MCP configuration completed"
    
    # Configure workspace trust settings for Kiro IDE
    echo "Configuring Kiro IDE workspace trust..."
    mkdir -p $HOME/.local/share/code-server/User
    
    # Create or update settings.json to trust the home folder
    cat > $HOME/.local/share/code-server/User/settings.json <<'SETTINGS_EOF'
    {
      "security.workspace.trust.enabled": true,
      "security.workspace.trust.startupPrompt": "never",
      "security.workspace.trust.emptyWindow": false,
      "security.workspace.trust.untrustedFiles": "open"
    }
    SETTINGS_EOF
    
    # Add trusted folders configuration
    mkdir -p $HOME/.kiro/settings
    cat > $HOME/.kiro/settings/trusted-workspaces.json <<'TRUST_EOF'
    {
      "trustedFolders": [
      "/home/coder"
      ]
    }
    TRUST_EOF
    
    echo "Kiro IDE workspace trust configuration completed"
    
    #Symlink Coder Agent
    ln -sf /tmp/coder.*/coder "$CODER_SCRIPT_BIN_DIR/coder" 
  EOT

  metadata {
    key          = "cpu"
    display_name = "CPU Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat cpu"
  }
  metadata {
    key          = "memory"
    display_name = "Memory Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat mem"
  }
  metadata {
    key          = "disk"
    display_name = "Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = "coder stat disk --path $HOME"
  }
}

module "coder-login" {
    count    = data.coder_workspace.me.start_count
    source   = "registry.coder.com/coder/coder-login/coder"
    version  = "1.1.0"
    agent_id = coder_agent.dev[0].id
}

module "code-server" {
    count    = data.coder_workspace.me.start_count
    source   = "registry.coder.com/coder/code-server/coder"
    version  = "1.3.1"
    agent_id       = coder_agent.dev[0].id
    folder         = local.home_folder
    subdomain = false
    order = 0
}

module "kiro" {
    count    = data.coder_workspace.me.start_count
    source   = "registry.coder.com/coder/kiro/coder"
    version  = "1.1.0"
    agent_id = coder_agent.dev[0].id
    order = 1
}

locals {
  hostname   = lower(data.coder_workspace.me.name)
  linux_user = "coder"
}

data "cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = false

  boundary = "//"

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/cloud-init/cloud-config.yaml.tftpl", {
      hostname   = local.hostname
      linux_user = local.linux_user
    })
  }

  part {
    filename     = "userdata.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/cloud-init/userdata.sh.tftpl", {
      linux_user = local.linux_user

      init_script = try(coder_agent.dev[0].init_script, "")
    })
  }
}

resource "aws_instance" "dev" {
  ami                  = data.aws_ami.ubuntu.id
  availability_zone    = "${data.coder_parameter.region.value}a"
  instance_type        = data.coder_parameter.instance_type.value
  iam_instance_profile = data.aws_iam_instance_profile.vm_instance_profile.name
  root_block_device {
    volume_size = data.coder_parameter.root_volume_size_gb.value
  }

  user_data = data.cloudinit_config.user_data.rendered
  tags = {
    Name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    # Required if you are using our example policy, see template README
    Coder_Provisioned = "true"
  }
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "coder_metadata" "workspace_info" {
  resource_id = aws_instance.dev.id
  item {
    key   = "region"
    value = data.coder_parameter.region.value
  }
  item {
    key   = "instance type"
    value = aws_instance.dev.instance_type
  }
  item {
    key   = "disk"
    value = "${aws_instance.dev.root_block_device[0].volume_size} GiB"
  }
}

resource "aws_ec2_instance_state" "dev" {
  instance_id = aws_instance.dev.id
  state       = data.coder_workspace.me.transition == "start" ? "running" : "stopped"
}
