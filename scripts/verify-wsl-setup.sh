#!/bin/bash
# WSL Prerequisites Verification Script
# Checks if all required tools are installed and configured

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  PHASE 0: PREREQUISITES VERIFICATION (WSL)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

ALL_GOOD=true

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check Distribution
echo -e "${YELLOW}🐧 WSL Distribution:${NC}"
cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2
echo ""

# Check Git
echo -e "${YELLOW}1️⃣  Checking Git...${NC}"
if command_exists git; then
    GIT_VERSION=$(git --version)
    echo -e "   ${GREEN}✅ Git installed: $GIT_VERSION${NC}"
    
    GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
    
    if [ -n "$GIT_USER" ] && [ -n "$GIT_EMAIL" ]; then
        echo -e "   ${GREEN}✅ Git configured: $GIT_USER <$GIT_EMAIL>${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Git not configured. Run: ./scripts/setup-wsl.sh${NC}"
        ALL_GOOD=false
    fi
else
    echo -e "   ${RED}❌ Git not installed${NC}"
    ALL_GOOD=false
fi

# Check Docker
echo ""
echo -e "${YELLOW}2️⃣  Checking Docker...${NC}"
if command_exists docker; then
    DOCKER_VERSION=$(docker --version)
    echo -e "   ${GREEN}✅ Docker installed: $DOCKER_VERSION${NC}"
    
    if docker ps &>/dev/null; then
        echo -e "   ${GREEN}✅ Docker daemon is running${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Docker daemon not accessible${NC}"
        echo -e "      ${GRAY}Enable WSL integration in Docker Desktop${NC}"
        ALL_GOOD=false
    fi
else
    echo -e "   ${YELLOW}⚠️  Docker CLI not found in WSL${NC}"
    echo -e "      ${GRAY}Enable WSL integration in Docker Desktop:${NC}"
    echo -e "      ${GRAY}Settings → Resources → WSL Integration → Ubuntu${NC}"
    ALL_GOOD=false
fi

# Check AWS CLI
echo ""
echo -e "${YELLOW}3️⃣  Checking AWS CLI...${NC}"
if command_exists aws; then
    AWS_VERSION=$(aws --version 2>&1)
    echo -e "   ${GREEN}✅ AWS CLI installed: $AWS_VERSION${NC}"
    
    if aws sts get-caller-identity &>/dev/null; then
        echo -e "   ${GREEN}✅ AWS credentials configured${NC}"
        ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
        echo -e "      ${GRAY}Account: $ACCOUNT${NC}"
        echo -e "      ${GRAY}User: $ARN${NC}"
    else
        echo -e "   ${YELLOW}⚠️  AWS credentials not configured${NC}"
        echo -e "      ${GRAY}Run: aws configure${NC}"
        ALL_GOOD=false
    fi
else
    echo -e "   ${RED}❌ AWS CLI not installed${NC}"
    ALL_GOOD=false
fi

# Check kubectl
echo ""
echo -e "${YELLOW}4️⃣  Checking kubectl...${NC}"
if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | head -1 | awk '{print $2}')
    echo -e "   ${GREEN}✅ kubectl installed: $KUBECTL_VERSION${NC}"
else
    echo -e "   ${RED}❌ kubectl not installed${NC}"
    ALL_GOOD=false
fi

# Check Terraform
echo ""
echo -e "${YELLOW}5️⃣  Checking Terraform...${NC}"
if command_exists terraform; then
    TERRAFORM_VERSION=$(terraform version -json 2>/dev/null | jq -r '.terraform_version')
    if [ -z "$TERRAFORM_VERSION" ]; then
        TERRAFORM_VERSION=$(terraform version | head -1 | awk '{print $2}')
    fi
    echo -e "   ${GREEN}✅ Terraform installed: $TERRAFORM_VERSION${NC}"
else
    echo -e "   ${RED}❌ Terraform not installed${NC}"
    ALL_GOOD=false
fi

# Check Helm
echo ""
echo -e "${YELLOW}6️⃣  Checking Helm...${NC}"
if command_exists helm; then
    HELM_VERSION=$(helm version --short 2>/dev/null | cut -d'+' -f1)
    echo -e "   ${GREEN}✅ Helm installed: $HELM_VERSION${NC}"
else
    echo -e "   ${RED}❌ Helm not installed${NC}"
    ALL_GOOD=false
fi

# Check Node.js
echo ""
echo -e "${YELLOW}7️⃣  Checking Node.js...${NC}"
if command_exists node; then
    NODE_VERSION=$(node --version)
    echo -e "   ${GREEN}✅ Node.js installed: $NODE_VERSION${NC}"
    
    if command_exists npm; then
        NPM_VERSION=$(npm --version)
        echo -e "   ${GREEN}✅ npm installed: v$NPM_VERSION${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  Node.js not installed natively in WSL${NC}"
    echo -e "      ${GRAY}Run: ./scripts/setup-wsl.sh${NC}"
    ALL_GOOD=false
fi

# Check useful utilities
echo ""
echo -e "${YELLOW}8️⃣  Checking Utilities...${NC}"
UTILS_GOOD=true
for util in curl wget jq tree vim; do
    if command_exists $util; then
        echo -e "   ${GREEN}✅ $util installed${NC}"
    else
        echo -e "   ${YELLOW}⚠️  $util not installed (nice to have)${NC}"
        UTILS_GOOD=false
    fi
done

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
if [ "$ALL_GOOD" = true ]; then
    echo "║  ✅ ALL PREREQUISITES MET! YOU'RE READY FOR PHASE 1!      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}🚀 Next step: Start Phase 1 - Infrastructure Foundation${NC}"
else
    echo "║  ⚠️  SOME ITEMS NEED ATTENTION                             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${YELLOW}📋 Please address items marked with ❌ or ⚠️ above${NC}"
    echo ""
    echo -e "${CYAN}To fix issues:${NC}"
    echo "  • Run: ./scripts/setup-wsl.sh"
    echo "  • Enable Docker WSL integration in Docker Desktop"
    echo "  • Configure AWS: aws configure"
fi

echo ""
echo -e "${GRAY}Additional Information:${NC}"
echo -e "  ${GRAY}• Project Directory: $(pwd)${NC}"
echo -e "  ${GRAY}• Shell: $SHELL${NC}"
echo -e "  ${GRAY}• User: $USER${NC}"
echo -e "  ${GRAY}• Hostname: $(hostname)${NC}"
echo ""
