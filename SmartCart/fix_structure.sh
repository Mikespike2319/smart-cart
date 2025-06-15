#!/bin/bash

# Smart Cart Directory Structure Fix Script
echo "🔧 Fixing Smart Cart directory structure..."

# Create backup
echo "📦 Creating backup..."
mkdir -p backup_$(date +%Y%m%d_%H%M%S)
cp -r . backup_$(date +%Y%m%d_%H%M%S)/

# Move backend and infrastructure to root level (if they exist in SmartCart/)
if [ -d "SmartCart/backend" ]; then
    echo "📁 Moving backend to root level..."
    mv SmartCart/backend ../backend
fi

if [ -d "SmartCart/infrastructure" ]; then
    echo "📁 Moving infrastructure to root level..."
    mv SmartCart/infrastructure ../infrastructure
fi

if [ -d "SmartCart/kubernetes" ]; then
    echo "📁 Moving kubernetes to root level..."
    mv SmartCart/kubernetes ../kubernetes
fi

if [ -d "SmartCart/scripts" ]; then
    echo "📁 Moving scripts to root level..."
    mv SmartCart/scripts ../scripts
fi

# Remove any remaining non-iOS files from SmartCart directory
echo "🧹 Cleaning up non-iOS files..."
find SmartCart/ -name "*.py" -delete
find SmartCart/ -name "*.tf" -delete
find SmartCart/ -name "*.yaml" -delete
find SmartCart/ -name "*.yml" -delete
find SmartCart/ -name "*.md" -delete
find SmartCart/ -name "*.txt" -delete
find SmartCart/ -name "requirements.txt" -delete
find SmartCart/ -name "Dockerfile" -delete
find SmartCart/ -name ".env*" -delete

# Keep only Swift files and iOS-related files
echo "✅ Keeping only iOS files in SmartCart directory..."
find SmartCart/ -type f ! \( -name "*.swift" -o -name "*.json" -o -name "Info.plist" -o -name "*.xcassets" -o -name "*.entitlements" \) -delete

echo "🎉 Directory structure fixed!"
echo ""
echo "📁 New structure:"
echo "Smart Cart/"
echo "├── SmartCart/           # iOS source files only"
echo "├── backend/            # Backend API"
echo "├── infrastructure/     # Terraform & K8s"
echo "└── SmartCart.xcodeproj/"
echo ""
echo "⚠️  NOTE: Move the xcodeproj back to root if needed:"
echo "mv SmartCart.xcodeproj ../SmartCart.xcodeproj" 