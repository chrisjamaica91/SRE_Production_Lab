# Phase 0 Setup Verification Script
# This checks all prerequisites for the SRE Lab project

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 0: PREREQUISITES & SETUP VERIFICATION              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$allGood = $true

# Function to check command availability
function Test-Command {
    param($CommandName)
    try {
        Get-Command $CommandName -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check Git
Write-Host "1️⃣  Checking Git..." -ForegroundColor Yellow
if (Test-Command "git") {
    $gitVersion = git --version
    Write-Host "   ✅ Git installed: $gitVersion" -ForegroundColor Green
    
    # Check Git configuration
    $gitUser = git config --global user.name
    $gitEmail = git config --global user.email
    
    if ($gitUser -and $gitEmail) {
        Write-Host "   ✅ Git configured: $gitUser <$gitEmail>" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Git not configured. Run: .\scripts\setup-git.ps1" -ForegroundColor Yellow
        $allGood = $false
    }
} else {
    Write-Host "   ❌ Git not installed" -ForegroundColor Red
    Write-Host "      Download from: https://git-scm.com/download/windows" -ForegroundColor Gray
    $allGood = $false
}

# Check Docker
Write-Host "`n2️⃣  Checking Docker..." -ForegroundColor Yellow
if (Test-Command "docker") {
    $dockerVersion = docker --version
    Write-Host "   ✅ Docker installed: $dockerVersion" -ForegroundColor Green
    
    # Check if Docker is running
    try {
        docker ps | Out-Null 2>&1
        Write-Host "   ✅ Docker daemon is running" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Docker daemon not running. Start Docker Desktop." -ForegroundColor Yellow
        $allGood = $false
    }
} else {
    Write-Host "   ❌ Docker not installed" -ForegroundColor Red
    Write-Host "      Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Gray
    $allGood = $false
}

# Check AWS CLI
Write-Host "`n3️⃣  Checking AWS CLI..." -ForegroundColor Yellow
if (Test-Command "aws") {
    $awsVersion = aws --version
    Write-Host "   ✅ AWS CLI installed: $awsVersion" -ForegroundColor Green
    
    # Check AWS credentials
    try {
        $awsIdentity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ AWS credentials configured" -ForegroundColor Green
            $identity = $awsIdentity | ConvertFrom-Json
            Write-Host "      Account: $($identity.Account)" -ForegroundColor Gray
            Write-Host "      User: $($identity.Arn)" -ForegroundColor Gray
        } else {
            Write-Host "   ⚠️  AWS credentials not configured. Run: aws configure" -ForegroundColor Yellow
            $allGood = $false
        }
    } catch {
        Write-Host "   ⚠️  AWS credentials not configured. Run: aws configure" -ForegroundColor Yellow
        $allGood = $false
    }
} else {
    Write-Host "   ❌ AWS CLI not installed" -ForegroundColor Red
    Write-Host "      Download from: https://aws.amazon.com/cli/" -ForegroundColor Gray
    $allGood = $false
}

# Check kubectl
Write-Host "`n4️⃣  Checking kubectl..." -ForegroundColor Yellow
if (Test-Command "kubectl") {
    $kubectlVersion = kubectl version --client --short 2>&1 | Select-String "Client Version"
    Write-Host "   ✅ kubectl installed: $kubectlVersion" -ForegroundColor Green
} else {
    Write-Host "   ❌ kubectl not installed" -ForegroundColor Red
    Write-Host "      Install: https://kubernetes.io/docs/tasks/tools/" -ForegroundColor Gray
    $allGood = $false
}

# Check Terraform
Write-Host "`n5️⃣  Checking Terraform..." -ForegroundColor Yellow
if (Test-Command "terraform") {
    $terraformVersion = terraform version -json | ConvertFrom-Json
    Write-Host "   ✅ Terraform installed: v$($terraformVersion.terraform_version)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Terraform not installed" -ForegroundColor Red
    Write-Host "      Install: https://developer.hashicorp.com/terraform/downloads" -ForegroundColor Gray
    $allGood = $false
}

# Check Helm
Write-Host "`n6️⃣  Checking Helm..." -ForegroundColor Yellow
if (Test-Command "helm") {
    $helmVersion = helm version --short 2>&1
    Write-Host "   ✅ Helm installed: $helmVersion" -ForegroundColor Green
} else {
    Write-Host "   ❌ Helm not installed" -ForegroundColor Red
    Write-Host "      Install: https://helm.sh/docs/intro/install/" -ForegroundColor Gray
    $allGood = $false
}

# Check Node.js
Write-Host "`n7️⃣  Checking Node.js..." -ForegroundColor Yellow
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Host "   ✅ Node.js installed: $nodeVersion" -ForegroundColor Green
    
    if (Test-Command "npm") {
        $npmVersion = npm --version
        Write-Host "   ✅ npm installed: v$npmVersion" -ForegroundColor Green
    }
} else {
    Write-Host "   ❌ Node.js not installed" -ForegroundColor Red
    Write-Host "      Download from: https://nodejs.org/" -ForegroundColor Gray
    $allGood = $false
}

# Check VS Code
Write-Host "`n8️⃣  Checking Visual Studio Code..." -ForegroundColor Yellow
if (Test-Command "code") {
    $codeVersion = code --version | Select-Object -First 1
    Write-Host "   ✅ VS Code installed: $codeVersion" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  VS Code CLI not in PATH (but you're using it!)" -ForegroundColor Cyan
    Write-Host "      This is fine - VS Code is working" -ForegroundColor Gray
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "║  ✅ ALL PREREQUISITES MET! YOU'RE READY FOR PHASE 1!      ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    Write-Host "🚀 Next step: Start Phase 1 - Infrastructure Foundation`n" -ForegroundColor Green
} else {
    Write-Host "║  ⚠️  SOME ITEMS NEED ATTENTION                             ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    Write-Host "📋 Please install/configure the items marked with ❌ or ⚠️ above`n" -ForegroundColor Yellow
}

# Additional checks
Write-Host "Additional Information:" -ForegroundColor Cyan
Write-Host "  • Project Directory: $PWD" -ForegroundColor Gray
Write-Host "  • PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "  • Operating System: Windows $(([System.Environment]::OSVersion.Version).Major)`n" -ForegroundColor Gray
