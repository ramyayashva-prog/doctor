# OpenAI Render Troubleshooting Guide

This guide helps you resolve the "Failed to generate AI summary" 500 error on Render deployment.

## 🚨 **Current Issue: 500 Error on Render**

You're getting this error on Render:
```json
{
    "message": "Failed to generate AI summary",
    "success": false
}
```

## 🔍 **Step-by-Step Debugging**

### **Step 1: Check OpenAI Configuration**

Test your Render deployment with these debug endpoints:

#### **Debug OpenAI Configuration:**
```bash
curl https://your-app-name.onrender.com/debug/openai-config
```

**Expected Response if Working:**
```json
{
  "success": true,
  "debug_info": {
    "openai_api_key_present": true,
    "openai_api_key_format": "sk-proj-abc...xyz",
    "openai_api_key_valid_format": true,
    "environment_vars": {
      "OPENAI_API_KEY": "sk-proj-abc123..."
    }
  }
}
```

#### **Test OpenAI API Connection:**
```bash
curl https://your-app-name.onrender.com/debug/test-openai
```

**Expected Response if Working:**
```json
{
  "success": true,
  "openai_response": "Hello, OpenAI API is working!",
  "model_used": "gpt-3.5-turbo",
  "tokens_used": 25,
  "message": "OpenAI API test successful"
}
```

### **Step 2: Fix Common Issues**

#### **Issue 1: OpenAI API Key Not Set**

**Symptoms:**
- `openai_api_key_present: false`
- `"OPENAI_API_KEY not found in environment variables"`

**Solution:**
1. **Get OpenAI API Key:**
   - Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
   - Create new API key
   - Copy the key (starts with `sk-`)

2. **Set in Render Dashboard:**
   - Go to your Render service dashboard
   - Click "Environment" tab
   - Find `OPENAI_API_KEY`
   - Click "Edit" and paste your API key
   - Click "Save Changes"
   - Wait for auto-redeploy

#### **Issue 2: Invalid API Key Format**

**Symptoms:**
- `openai_api_key_valid_format: false`
- `"Invalid API key format (should start with sk-)"`

**Solution:**
- Ensure your API key starts with `sk-`
- Check for extra spaces or characters
- Regenerate API key if needed

#### **Issue 3: OpenAI API Quota/Billing Issues**

**Symptoms:**
- `"insufficient_quota"` error
- `"billing_not_setup"` error

**Solution:**
1. **Check OpenAI Billing:**
   - Go to [https://platform.openai.com/account/billing](https://platform.openai.com/account/billing)
   - Add payment method if needed
   - Check usage limits

2. **Verify Account Status:**
   - Ensure account is active
   - Check for any restrictions

#### **Issue 4: Rate Limiting**

**Symptoms:**
- `"rate_limit_exceeded"` error
- Intermittent failures

**Solution:**
- Wait a few minutes and try again
- Implement request throttling in your app
- Consider upgrading OpenAI plan

### **Step 3: Verify Render Environment Variables**

#### **Check All Environment Variables:**
```bash
curl https://your-app-name.onrender.com/debug/openai-config
```

Look for these in the response:
```json
{
  "environment_vars": {
    "OPENAI_API_KEY": "sk-proj-abc123...",
    "MONGODB_URI": "mongodb+srv://...",
    "JWT_SECRET_KEY": "...",
    "PORT": "5000"
  }
}
```

#### **Missing Variables:**
If any variables are missing, add them in Render Dashboard:
1. Go to Service → Environment
2. Add missing variables
3. Save and redeploy

### **Step 4: Test AI Summary Endpoint**

After fixing the configuration, test the actual endpoint:

```bash
# First, get auth token
curl -X POST https://your-app-name.onrender.com/doctor-login \
  -H "Content-Type: application/json" \
  -d '{"email":"testdoctor@example.com","password":"testpass123"}'

# Then test AI summary (replace TOKEN and PATIENT_ID)
curl -X GET "https://your-app-name.onrender.com/doctor/patient/PATIENT_ID/ai-summary" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN"
```

**Expected Success Response:**
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

## 🔧 **Advanced Debugging**

### **Check Render Logs**

1. **Go to Render Dashboard:**
   - Click on your service
   - Click "Logs" tab
   - Look for OpenAI-related errors

2. **Common Error Messages:**
   ```
   ❌ OpenAI API key not found in environment variables
   ❌ Invalid OpenAI API key format (should start with sk-)
   ❌ OpenAI API call failed: insufficient_quota
   ❌ OpenAI API call failed: invalid_api_key
   ```

### **Test Local vs Render**

#### **Local Test:**
```bash
# Test locally first
curl http://localhost:5000/debug/openai-config
curl http://localhost:5000/debug/test-openai
```

#### **Render Test:**
```bash
# Then test on Render
curl https://your-app-name.onrender.com/debug/openai-config
curl https://your-app-name.onrender.com/debug/test-openai
```

### **Environment Variable Debugging**

Create a simple test endpoint to check all environment variables:

```bash
curl https://your-app-name.onrender.com/debug/openai-config
```

Look for:
- `openai_api_key_present: true`
- `openai_api_key_valid_format: true`
- Correct API key format in `environment_vars`

## 🚀 **Quick Fix Checklist**

- [ ] **Get OpenAI API Key** from platform.openai.com
- [ ] **Set OPENAI_API_KEY** in Render Dashboard → Environment
- [ ] **Wait for redeploy** (automatic after env var change)
- [ ] **Test debug endpoint** `/debug/openai-config`
- [ ] **Test OpenAI connection** `/debug/test-openai`
- [ ] **Test AI summary endpoint** with proper auth
- [ ] **Check OpenAI billing** if quota errors occur

## 💰 **Cost Management**

### **OpenAI Pricing:**
- **GPT-3.5-turbo:** ~$0.002 per 1K tokens
- **Typical AI Summary:** ~500-1000 tokens
- **Estimated Cost:** $0.001-0.002 per summary

### **Cost Optimization:**
1. **Set Usage Limits** in OpenAI dashboard
2. **Monitor Usage** regularly
3. **Cache Results** to avoid regenerating summaries
4. **Implement Rate Limiting** in your app

## 🆘 **Still Having Issues?**

### **Check These:**

1. **Render Service Status:**
   - Is your service running?
   - Check service logs for errors

2. **OpenAI Account:**
   - Is your account active?
   - Do you have sufficient credits?
   - Is the API key valid?

3. **Network Issues:**
   - Can Render reach OpenAI API?
   - Check for firewall restrictions

4. **Code Issues:**
   - Is the OpenAI library installed?
   - Are there import errors?

### **Contact Support:**

- **Render Support:** Check Render documentation
- **OpenAI Support:** OpenAI Help Center
- **Check Logs:** Always check server logs first

## 📝 **Success Verification**

You'll know it's working when:

1. **Debug endpoints return success:**
   ```json
   {
     "success": true,
     "openai_api_key_present": true,
     "openai_api_key_valid_format": true
   }
   ```

2. **AI summary endpoint returns:**
   ```json
   {
     "success": true,
     "ai_summary": "COMPREHENSIVE MEDICAL SUMMARY...",
     "summary_stats": {...}
   }
   ```

3. **No more 500 errors** in Render logs

---

**Remember:** The most common issue is simply not setting the `OPENAI_API_KEY` environment variable in Render Dashboard. Double-check this first!
