# PowerShell deployment script for OpenAI fixes

Write-Host "🚀 Deploying OpenAI fixes to Render..." -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# Check git status
Write-Host "📋 Checking git status..." -ForegroundColor Yellow
git status

# Add all changes
Write-Host "📦 Adding all changes..." -ForegroundColor Yellow
git add .

# Commit changes
Write-Host "💾 Committing changes..." -ForegroundColor Yellow
git commit -m "Fix OpenAI client proxy issue and add root endpoint

- Remove problematic proxy settings from OpenAI client initialization
- Add root endpoint with API information  
- Enhance error handling for OpenAI API calls
- Fix ObjectId JSON serialization (already working)
- All endpoints should now work properly on Render"

# Push to repository
Write-Host "🌐 Pushing to repository..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "✅ Deployment initiated!" -ForegroundColor Green
Write-Host "⏳ Render will auto-deploy in 2-5 minutes" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Test after deployment:" -ForegroundColor Yellow
Write-Host "Invoke-WebRequest -Uri 'https://doctor-9don.onrender.com/debug/test-openai' -Method GET" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Check deployment status in Render Dashboard" -ForegroundColor Cyan
