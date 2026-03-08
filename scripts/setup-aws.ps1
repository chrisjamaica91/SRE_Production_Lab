# AWS Configuration Helper Script
# This script helps you set up AWS credentials for the SRE Lab project

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           AWS CREDENTIALS CONFIGURATION                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "This script will help you configure AWS CLI credentials.`n" -ForegroundColor Yellow

# Check if AWS CLI is installed
try {wslwsl
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI is installed: $awsVersion`n" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install it first: https://aws.amazon.com/cli/`n" -ForegroundColor Yellow
    exit 1
}

# Information message
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "WHAT YOU'LL NEED:" -ForegroundColor Cyan
Write-Host "  1. AWS Account (sign up at: https://aws.amazon.com)" -ForegroundColor Gray
Write-Host "  2. AWS Access Key ID" -ForegroundColor Gray
Write-Host "  3. AWS Secret Access Key" -ForegroundColor Gray
Write-Host "`nWHERE TO FIND YOUR CREDENTIALS:" -ForegroundColor Cyan
Write-Host "  1. Log into AWS Console: https://console.aws.amazon.com" -ForegroundColor Gray
Write-Host "  2. Click your name (top-right) → Security Credentials" -ForegroundColor Gray
Write-Host "  3. Scroll to 'Access keys' section" -ForegroundColor Gray
Write-Host "  4. Click 'Create access key'" -ForegroundColor Gray
Write-Host "  5. Choose 'Command Line Interface (CLI)'" -ForegroundColor Gray
Write-Host "  6. Copy the Access Key ID and Secret Access Key" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Gray

# Check if already configured
$currentConfig = $false
try {
    $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
    if ($identity.Account) {
        Write-Host "⚠️  AWS credentials are already configured!" -ForegroundColor Yellow
        Write-Host "   Current Account: $($identity.Account)" -ForegroundColor Gray
        Write-Host "   Current User: $($identity.Arn)`n" -ForegroundColor Gray
        
        $reconfigure = Read-Host "Do you want to reconfigure? (y/n)"
        if ($reconfigure -ne 'y') {
            Write-Host "`n✅ Keeping existing configuration. You're all set!`n" -ForegroundColor Green
            exit 0
        }
        $currentConfig = $true
    }
} catch {
    # No credentials configured, continue
}

# Start configuration
Write-Host "`n═══ CONFIGURATION ═══`n" -ForegroundColor Cyan

$configureNow = Read-Host "Do you have your AWS credentials ready? (y/n)"

if ($configureNow -eq 'y') {
    Write-Host "`nStarting AWS CLI configuration...`n" -ForegroundColor Yellow
    Write-Host "You'll be prompted for:" -ForegroundColor Gray
    Write-Host "  • AWS Access Key ID" -ForegroundColor Gray
    Write-Host "  • AWS Secret Access Key" -ForegroundColor Gray
    Write-Host "  • Default region (recommended: us-east-1)" -ForegroundColor Gray
    Write-Host "  • Default output format (recommended: json)`n" -ForegroundColor Gray
    
    # Run AWS configure
    aws configure
    
    # Verify configuration
    Write-Host "`n═══ VERIFICATION ═══`n" -ForegroundColor Cyan
    
    try {
        $identity = aws sts get-caller-identity | ConvertFrom-Json
        Write-Host "✅ AWS credentials successfully configured!`n" -ForegroundColor Green
        Write-Host "Account ID: $($identity.Account)" -ForegroundColor Gray
        Write-Host "User ARN: $($identity.Arn)" -ForegroundColor Gray
        Write-Host "User ID: $($identity.UserId)`n" -ForegroundColor Gray
        
        # Get configured region
        $region = aws configure get region
        Write-Host "Default Region: $region" -ForegroundColor Gray
        
        Write-Host "`n🎉 You're ready to start building AWS infrastructure!`n" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Configuration failed or credentials are invalid." -ForegroundColor Red
        Write-Host "Please verify your Access Key ID and Secret Access Key.`n" -ForegroundColor Yellow
        Write-Host "Run this script again or manually configure: aws configure`n" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNo problem! Here's what to do:`n" -ForegroundColor Yellow
    Write-Host "1. Create an AWS account: https://aws.amazon.com" -ForegroundColor Gray
    Write-Host "2. Get your access keys (see instructions above)" -ForegroundColor Gray
    Write-Host "3. Run this script again: .\scripts\setup-aws.ps1" -ForegroundColor Gray
    Write-Host "   OR manually configure: aws configure`n" -ForegroundColor Gray
}

# Additional information
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "💡 TIPS:" -ForegroundColor Cyan
Write-Host "  • Keep your Secret Access Key safe (treat it like a password)" -ForegroundColor Gray
Write-Host "  • Never commit credentials to Git" -ForegroundColor Gray
Write-Host "  • AWS Free Tier gives you 12 months of free resources" -ForegroundColor Gray
Write-Host "  • This project costs ~$200/month (can use free tier for some)" -ForegroundColor Gray
Write-Host "  • Set up billing alerts in AWS Console" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Gray
