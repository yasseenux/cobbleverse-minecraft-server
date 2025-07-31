#!/bin/bash

# GitHub Upload Script for Cobbleverse Server
# This script will help you upload your project to GitHub

echo "🚀 Cobbleverse Minecraft Server - GitHub Upload Helper"
echo "=================================================="
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a Git repository!"
    echo "Please run this script from the project root directory."
    exit 1
fi

echo "📁 Current project status:"
git status --short
echo ""

# Get repository name
echo "📝 Please provide the following information:"
read -p "Repository name (e.g., cobbleverse-minecraft-server): " REPO_NAME
read -p "Your GitHub username: " GITHUB_USERNAME
read -p "Repository description (optional): " REPO_DESCRIPTION

# Validate inputs
if [ -z "$REPO_NAME" ] || [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ Error: Repository name and GitHub username are required!"
    exit 1
fi

# Construct repository URL
REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

echo ""
echo "🔧 Configuration:"
echo "Repository: $REPO_NAME"
echo "Username: $GITHUB_USERNAME"
echo "URL: $REPO_URL"
echo ""

# Ask for confirmation
read -p "Continue with these settings? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ Upload cancelled."
    exit 1
fi

echo ""
echo "📋 Next steps:"
echo "1. Go to GitHub.com and create a new repository"
echo "2. Repository name: $REPO_NAME"
echo "3. Description: $REPO_DESCRIPTION"
echo "4. Make sure it's PUBLIC (for Railway template sharing)"
echo "5. DON'T initialize with README, .gitignore, or license (we have these)"
echo ""
echo "After creating the repository on GitHub, run these commands:"
echo ""
echo "git remote add origin $REPO_URL"
echo "git branch -M main"
echo "git push -u origin main"
echo ""
echo "🎉 Then your Cobbleverse server will be ready for Railway deployment!"
echo ""
echo "🔗 Railway deployment options:"
echo "1. One-click deploy: Connect your GitHub repo to Railway"
echo "2. Template deploy: Use the railway-template.yml"
echo "3. CLI deploy: railway up"
echo ""
echo "📖 Check the README.md for detailed deployment instructions."
