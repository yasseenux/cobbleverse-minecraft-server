@echo off
REM GitHub Upload Script for Cobbleverse Server (Windows)
REM This script will help you upload your project to GitHub

echo 🚀 Cobbleverse Minecraft Server - GitHub Upload Helper
echo ==================================================
echo.

REM Check if we're in a git repository
if not exist ".git" (
    echo ❌ Error: Not in a Git repository!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo 📁 Current project status:
git status --short
echo.

REM Get repository information
echo 📝 Please provide the following information:
set /p REPO_NAME="Repository name (e.g., cobbleverse-minecraft-server): "
set /p GITHUB_USERNAME="Your GitHub username: "
set /p REPO_DESCRIPTION="Repository description (optional): "

REM Validate inputs
if "%REPO_NAME%"=="" (
    echo ❌ Error: Repository name is required!
    pause
    exit /b 1
)
if "%GITHUB_USERNAME%"=="" (
    echo ❌ Error: GitHub username is required!
    pause
    exit /b 1
)

REM Construct repository URL
set REPO_URL=https://github.com/%GITHUB_USERNAME%/%REPO_NAME%.git

echo.
echo 🔧 Configuration:
echo Repository: %REPO_NAME%
echo Username: %GITHUB_USERNAME%
echo URL: %REPO_URL%
echo.

REM Ask for confirmation
set /p CONFIRM="Continue with these settings? (y/N): "
if not "%CONFIRM%"=="y" if not "%CONFIRM%"=="Y" (
    echo ❌ Upload cancelled.
    pause
    exit /b 1
)

echo.
echo 📋 Next steps:
echo 1. Go to GitHub.com and create a new repository
echo 2. Repository name: %REPO_NAME%
echo 3. Description: %REPO_DESCRIPTION%
echo 4. Make sure it's PUBLIC (for Railway template sharing)
echo 5. DON'T initialize with README, .gitignore, or license (we have these)
echo.
echo After creating the repository on GitHub, run these commands:
echo.
echo git remote add origin %REPO_URL%
echo git branch -M main
echo git push -u origin main
echo.
echo 🎉 Then your Cobbleverse server will be ready for Railway deployment!
echo.
echo 🔗 Railway deployment options:
echo 1. One-click deploy: Connect your GitHub repo to Railway
echo 2. Template deploy: Use the railway-template.yml
echo 3. CLI deploy: railway up
echo.
echo 📖 Check the README.md for detailed deployment instructions.
echo.
pause
