# PowerShell deployment script for simplified OpenAI fix

Write-Host "🚀 Deploying Simplified OpenAI Fix..." -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check git status
Write-Host "📋 Checking git status..." -ForegroundColor Yellow
git status

# Add all changes
Write-Host "📦 Adding all changes..." -ForegroundColor Yellow
git add .

# Commit changes
Write-Host "💾 Committing changes..." -ForegroundColor Yellow
git commit -m "Simplify OpenAI implementation with fallback

- Downgrade OpenAI library to version 1.3.0 for compatibility
- Use simple openai.api_key initialization method
- Add fallback summary generation when OpenAI fails
- Ensure AI summary endpoint always returns success
- Remove complex version compatibility code
- Focus on reliable, simple implementation"

# Push to repository
Write-Host "🌐 Pushing to repository..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "✅ Deployment initiated!" -ForegroundColor Green
Write-Host "⏳ Render will auto-deploy in 3-5 minutes" -ForegroundColor Cyan
Write-Host ""
Write-Host "🧪 Test after deployment:" -ForegroundColor Yellow
Write-Host "1. OpenAI API Test:" -ForegroundColor Gray
Write-Host "   Invoke-WebRequest -Uri 'https://doctor-9don.onrender.com/debug/test-openai' -Method GET" -ForegroundColor Gray
Write-Host ""
Write-Host "2. AI Summary Test (should work with fallback):" -ForegroundColor Gray
Write-Host "   python test_ai_summary_debug.py" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Direct AI Summary Test:" -ForegroundColor Gray
Write-Host "   Get auth token and test: /doctor/patient/PATIENT_ID/ai-summary" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 Expected Results:" -ForegroundColor Cyan
Write-Host "- OpenAI test: Should work with simple method" -ForegroundColor White
Write-Host "- AI Summary: Will work with either AI or fallback" -ForegroundColor White
Write-Host "- No more 500 errors on AI summary endpoint" -ForegroundColor White
Write-Host ""
Write-Host "🔍 If still failing, check Render logs for specific errors" -ForegroundColor Red
