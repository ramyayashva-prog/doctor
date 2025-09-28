# PowerShell deployment script for OpenAI compatibility fixes

Write-Host "🚀 Deploying OpenAI Compatibility Fixes..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# Check git status
Write-Host "📋 Checking git status..." -ForegroundColor Yellow
git status

# Add all changes
Write-Host "📦 Adding all changes..." -ForegroundColor Yellow
git add .

# Commit changes
Write-Host "💾 Committing changes..." -ForegroundColor Yellow
git commit -m "Fix OpenAI library compatibility issues

- Add version compatibility for OpenAI client initialization
- Support both modern and legacy OpenAI API calls
- Add OpenAI library version detection
- Enhanced error handling with fallback methods
- Fix proxy parameter issues for all OpenAI versions
- Comprehensive debugging for AI summary endpoint"

# Push to repository
Write-Host "🌐 Pushing to repository..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "✅ Deployment initiated!" -ForegroundColor Green
Write-Host "⏳ Render will auto-deploy in 2-5 minutes" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Test after deployment:" -ForegroundColor Yellow
Write-Host "1. OpenAI API Test:" -ForegroundColor Gray
Write-Host "   Invoke-WebRequest -Uri 'https://doctor-9don.onrender.com/debug/test-openai' -Method GET" -ForegroundColor Gray
Write-Host ""
Write-Host "2. AI Summary Test:" -ForegroundColor Gray
Write-Host "   python test_ai_summary_debug.py" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Check deployment status in Render Dashboard" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔍 If still failing, check Render logs for specific error messages" -ForegroundColor Red
