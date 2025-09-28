# OpenAI API Setup Guide for Patient AI Summary

This guide will help you set up the OpenAI API key required for the Patient AI Summary endpoints.

## 🔑 Step 1: Get OpenAI API Key

1. **Visit OpenAI Platform:**
   - Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
   - Sign in with your OpenAI account (create one if needed)

2. **Create API Key:**
   - Click "Create new secret key"
   - Give it a name (e.g., "Patient AI Summary")
   - Copy the key (starts with `sk-`)
   - **Important:** Save the key immediately - you won't be able to see it again!

## 🔧 Step 2: Configure Environment Variable

### Option A: Using .env file (Recommended)

1. **Create or edit .env file in your project root:**
   ```bash
   # In your doctor project directory
   echo "OPENAI_API_KEY=sk-your-actual-api-key-here" >> .env
   ```

2. **Example .env file content:**
   ```
   OPENAI_API_KEY=sk-proj-abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
   MONGODB_URI=mongodb+srv://ramya:XxFn6n0NXx0wBplV@cluster0.c1g1bm5.mongodb.net
   DATABASE_NAME=patients_db
   SENDER_EMAIL=ramya.sureshkumar.lm@gmail.com
   SENDER_PASSWORD=djqs dktf gqor gnqg
   JWT_SECRET_KEY=27982af8380786e1f2967dca145cc0ed
   JWT_ALGORITHM=HS256
   ```

### Option B: Using Environment Variables (System-wide)

#### Windows (PowerShell):
```powershell
$env:OPENAI_API_KEY="sk-your-actual-api-key-here"
```

#### Windows (Command Prompt):
```cmd
set OPENAI_API_KEY=sk-your-actual-api-key-here
```

#### Linux/macOS:
```bash
export OPENAI_API_KEY="sk-your-actual-api-key-here"
```

## 🚀 Step 3: Restart Backend Server

After setting up the API key, restart your backend server:

```bash
# Stop the current server (Ctrl+C)
# Then restart:
python app_mvc.py
```

## ✅ Step 4: Test the Setup

### Test with Postman:
1. Import the Patient AI Summary Postman Collection
2. Run the "Doctor Login" request
3. Run the "Get Patient AI Summary" request
4. You should see a successful AI-generated summary

### Test with cURL:
```bash
curl -X GET "http://localhost:5000/doctor/patient/PAT1758712159E182A3/ai-summary" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN"
```

### Expected Success Response:
```json
{
  "success": true,
  "patient_id": "PAT1758712159E182A3",
  "patient_name": "John Doe",
  "ai_summary": "COMPREHENSIVE MEDICAL SUMMARY\n\nPATIENT OVERVIEW:\n...",
  "summary_stats": {
    "total_medications": 1,
    "total_symptoms": 1,
    "total_food_entries": 3,
    ...
  }
}
```

## 💰 Cost Information

### OpenAI Pricing (as of 2025):
- **GPT-3.5-turbo:** ~$0.002 per 1K tokens
- **Typical AI Summary:** ~500-1000 tokens
- **Estimated Cost:** $0.001-0.002 per summary

### Cost Optimization Tips:
1. **Cache Results** - Don't regenerate summaries for unchanged data
2. **Limit Token Usage** - Current setup uses max 1000 tokens
3. **Monitor Usage** - Check your OpenAI dashboard regularly
4. **Set Usage Limits** - Configure spending limits in OpenAI dashboard

## 🔒 Security Best Practices

1. **Never Commit API Keys:**
   ```bash
   # Add to .gitignore
   echo ".env" >> .gitignore
   ```

2. **Use Environment Variables:**
   - Don't hardcode API keys in source code
   - Use environment variables or .env files

3. **Rotate Keys Regularly:**
   - Create new API keys periodically
   - Revoke old unused keys

4. **Monitor Usage:**
   - Check OpenAI dashboard for unusual activity
   - Set up billing alerts

## 🚨 Troubleshooting

### Common Issues:

#### 1. "OpenAI API key not found in .env file"
**Solutions:**
- Check if .env file exists in project root
- Verify OPENAI_API_KEY is spelled correctly
- Ensure no extra spaces around the key
- Restart the server after adding the key

#### 2. "Failed to generate AI summary"
**Possible Causes:**
- Invalid API key format
- Expired API key
- Insufficient OpenAI credits
- Network connectivity issues

#### 3. "Insufficient quota"
**Solutions:**
- Add payment method to OpenAI account
- Check billing settings
- Verify account status

### Debug Steps:

1. **Verify API Key Format:**
   ```bash
   # Should start with 'sk-'
   echo $OPENAI_API_KEY
   ```

2. **Test API Key Directly:**
   ```bash
   curl -H "Authorization: Bearer $OPENAI_API_KEY" \
        https://api.openai.com/v1/models
   ```

3. **Check Server Logs:**
   ```bash
   # Look for OpenAI-related errors
   tail -f server.log | grep -i openai
   ```

## 📞 Support

### OpenAI Support:
- [OpenAI Help Center](https://help.openai.com/)
- [OpenAI Community](https://community.openai.com/)

### Project Support:
- Check server logs for detailed error messages
- Verify all prerequisites are met
- Test with provided Postman collection

---

**Important:** Keep your OpenAI API key secure and never share it publicly. The AI summary feature requires an active OpenAI account with available credits.
