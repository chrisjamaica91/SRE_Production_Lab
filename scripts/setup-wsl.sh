#!/bin/bash
# WSL Setup Script for SRE Lab Project
# This installs missing tools and configures the WSL environment

set -e  # Exit on error

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║       WSL SETUP FOR SRE LAB PROJECT                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Update system packages
echo -e "${CYAN}📦 Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Installing Node.js (via NodeSource)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Install Node.js 18.x (LTS) - recommended for stability
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
echo ""
echo -e "${GREEN}✅ Node.js installed:${NC}"
node --version
echo -e "${GREEN}✅ npm installed:${NC}"
npm --version

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Installing Additional Useful Tools${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Install useful utilities
sudo apt install -y \
    build-essential \
    jq \
    tree \
    vim \
    net-tools \
    iputils-ping \
    telnet \
    dnsutils

echo ""
echo -e "${GREEN}✅ Additional tools installed${NC}"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Configuring Git${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if Git is already configured
GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_USER" ]; then
    echo -e "${YELLOW}Git user not configured. Let's set it up:${NC}"
    read -p "Enter your name (for Git commits): " GIT_NAME
    read -p "Enter your email (for Git commits): " GIT_MAIL
    
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_MAIL"
    git config --global init.defaultBranch main
    git config --global core.editor "vim"
    
    echo -e "${GREEN}✅ Git configured successfully${NC}"
else
    echo -e "${GREEN}✅ Git already configured:${NC}"
    echo "   Name: $GIT_USER"
    echo "   Email: $GIT_EMAIL"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Checking Docker Integration${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker CLI is available in WSL${NC}"
    docker --version
else
    echo -e "${YELLOW}⚠️  Docker CLI not found in WSL${NC}"
    echo ""
    echo "To enable Docker in WSL:"
    echo "1. Open Docker Desktop on Windows"
    echo "2. Go to Settings → Resources → WSL Integration"
    echo "3. Enable integration with Ubuntu"
    echo "4. Click 'Apply & Restart'"
    echo ""
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Checking AWS Configuration${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

if aws sts get-caller-identity &>/dev/null; then
    echo -e "${GREEN}✅ AWS credentials configured${NC}"
    aws sts get-caller-identity --output table
else
    echo -e "${YELLOW}⚠️  AWS credentials not configured${NC}"
    echo ""
    echo "To configure AWS CLI, run: aws configure"
    echo ""
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}Setting Up Project Aliases${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Add useful aliases to .bashrc if not already present
BASHRC="$HOME/.bashrc"

if ! grep -q "# SRE Lab Aliases" "$BASHRC"; then
    cat >> "$BASHRC" << 'EOF'

# SRE Lab Aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods --all-namespaces'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kgd='kubectl get deployments'
alias tf='terraform'
alias ll='ls -lah'
alias c='clear'

# Kubectl completion
source <(kubectl completion bash)
complete -F __start_kubectl k

EOF
    echo -e "${GREEN}✅ Useful aliases added to ~/.bashrc${NC}"
    echo "   Run 'source ~/.bashrc' or restart terminal to use them"
else
    echo -e "${GREEN}✅ Aliases already configured${NC}"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ WSL SETUP COMPLETE!                                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. If Docker isn't working, enable WSL integration in Docker Desktop"
echo "2. If AWS isn't configured, run: aws configure"
echo "3. Run: source ~/.bashrc (to load new aliases)"
echo "4. Run: ./scripts/verify-wsl-setup.sh (to verify everything)"
echo ""
echo -e "${CYAN}You're ready to start Phase 1! 🚀${NC}"
echo ""
