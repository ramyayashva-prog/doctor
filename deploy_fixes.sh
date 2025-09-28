#!/bin/bash
# Deployment script for OpenAI fixes

echo "🚀 Deploying OpenAI fixes to Render..."
echo "======================================"

# Check git status
echo "📋 Checking git status..."
git status

# Add all changes
echo "📦 Adding all changes..."
git add .

# Commit changes
echo "💾 Committing changes..."
git commit -m "Fix OpenAI client proxy issue and add root endpoint

- Remove problematic proxy settings from OpenAI client initialization
- Add root endpoint with API information
- Enhance error handling for OpenAI API calls
- Fix ObjectId JSON serialization (already working)
- All endpoints should now work properly on Render"

# Push to repository
echo "🌐 Pushing to repository..."
git push origin main

echo ""
echo "✅ Deployment initiated!"
echo "⏳ Render will auto-deploy in 2-5 minutes"
echo ""
echo "🧪 Test after deployment:"
echo "curl https://doctor-9don.onrender.com/debug/test-openai"
echo ""
echo "📊 Check deployment status in Render Dashboard"
