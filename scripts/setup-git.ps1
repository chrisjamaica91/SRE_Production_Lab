# Git Configuration Script
# Run this after installing Git

Write-Host "`n=== Git Configuration Setup ===`n" -ForegroundColor Cyan

# Check if Git is installed
try {
    $gitVersion = git --version
    Write-Host "✅ Git is installed: $gitVersion`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://git-scm.com/download/windows`n" -ForegroundColor Yellow
    exit 1
}

# Configure Git user
Write-Host "Let's configure your Git identity..." -ForegroundColor Yellow
$userName = Read-Host "Enter your name (for Git commits)"
$userEmail = Read-Host "Enter your email (for Git commits)"

git config --global user.name "$userName"
git config --global user.email "$userEmail"

# Set default branch name to main
git config --global init.defaultBranch main

# Set line ending preferences (important for cross-platform)
git config --global core.autocrlf true

# Set VS Code as default editor (if you want)
$useVSCode = Read-Host "Use VS Code as Git editor? (y/n)"
if ($useVSCode -eq 'y') {
    git config --global core.editor "code --wait"
}

Write-Host "`n✅ Git configuration complete!`n" -ForegroundColor Green

# Show configuration
Write-Host "Your Git configuration:" -ForegroundColor Cyan
git config --global --list | Select-String "user|init.defaultBranch|core.editor"

Write-Host "`nYou're ready to use Git! 🚀`n" -ForegroundColor Green
