# AI Summary Endpoint Troubleshooting Guide

## 🚨 **Current Issue:** AI Summary Endpoint Failing on Render

**Error:** `{"message": "Failed to generate AI summary", "success": false}`

## 🔍 **Step-by-Step Debugging Process**

### **Step 1: Check OpenAI Configuration**

Test the OpenAI configuration on your Render deployment:

```bash
curl https://doctor-9don.onrender.com/debug/openai-config
```

**Expected Response:**
```json
{
  "success": true,
  "debug_info": {
    "openai_api_key_present": true,
    "openai_api_key_valid_format": true,
    "openai_api_key_format": "sk-proj-abc...xyz"
  }
}
```

### **Step 2: Test OpenAI API Connection**

Test direct OpenAI API connectivity:

```bash
curl https://doctor-9don.onrender.com/debug/test-openai
```

**Expected Response:**
```json
{
  "success": true,
  "openai_response": "Hello, OpenAI API is working!",
  "model_used": "gpt-3.5-turbo",
  "tokens_used": 25,
  "message": "OpenAI API test successful"
}
```

### **Step 3: Test AI Summary with Authentication**

Get an auth token first:

```bash
# Get auth token
curl -X POST https://doctor-9don.onrender.com/doctor-login \
  -H "Content-Type: application/json" \
  -d '{"email":"testdoctor@example.com","password":"testpass123"}'
```

Then test AI summary:

```bash
# Test AI summary (replace TOKEN and PATIENT_ID)
curl -X GET "https://doctor-9don.onrender.com/doctor/patient/PATIENT_ID/ai-summary" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN"
```

## 🔧 **Common Issues & Solutions**

### **Issue 1: OpenAI API Key Not Configured**

**Symptoms:**
- `openai_api_key_present: false`
- `"Failed to generate AI summary"`

**Solution:**
1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create/get your API key
3. In Render Dashboard → Your Service → Environment
4. Set `OPENAI_API_KEY=sk-your-key-here`
5. Redeploy

### **Issue 2: OpenAI API Quota Exceeded**

**Symptoms:**
- `"insufficient_quota"` error
- API key is valid but requests fail

**Solution:**
1. Check [OpenAI Billing](https://platform.openai.com/account/billing)
2. Add payment method if needed
3. Check usage limits
4. Upgrade plan if necessary

### **Issue 3: Invalid API Key**

**Symptoms:**
- `"invalid_api_key"` error
- API key format issues

**Solution:**
1. Verify API key starts with `sk-`
2. Check for extra spaces or characters
3. Regenerate API key if needed
4. Update in Render environment variables

### **Issue 4: Rate Limiting**

**Symptoms:**
- `"rate_limit_exceeded"` error
- Intermittent failures

**Solution:**
1. Wait a few minutes and retry
2. Implement request throttling
3. Consider upgrading OpenAI plan

### **Issue 5: Network/Connection Issues**

**Symptoms:**
- `"connection"` or `"timeout"` errors
- Render can't reach OpenAI API

**Solution:**
1. Check Render service logs
2. Verify network connectivity
3. Try again after a few minutes

## 🧪 **Testing Script**

Create and run this test script to diagnose the issue:

```python
import requests
import json

def test_ai_summary_endpoint():
    base_url = "https://doctor-9don.onrender.com"
    
    print("🧪 Testing AI Summary Endpoint")
    print("=" * 50)
    
    # Step 1: Test OpenAI config
    print("1. Testing OpenAI configuration...")
    try:
        response = requests.get(f"{base_url}/debug/openai-config")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ OpenAI config: {data['debug_info']['openai_api_key_present']}")
        else:
            print(f"❌ OpenAI config failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ OpenAI config error: {e}")
        return False
    
    # Step 2: Test OpenAI API
    print("\n2. Testing OpenAI API connection...")
    try:
        response = requests.get(f"{base_url}/debug/test-openai")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ OpenAI API: {data['message']}")
        else:
            print(f"❌ OpenAI API failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ OpenAI API error: {e}")
        return False
    
    # Step 3: Test AI summary (requires auth)
    print("\n3. Testing AI summary endpoint...")
    try:
        # Get auth token
        login_response = requests.post(
            f"{base_url}/doctor-login",
            json={"email": "testdoctor@example.com", "password": "testpass123"}
        )
        
        if login_response.status_code == 200:
            token = login_response.json().get('token')
            print("✅ Authentication successful")
            
            # Test AI summary
            summary_response = requests.get(
                f"{base_url}/doctor/patient/PATIENT_ID/ai-summary",
                headers={"Authorization": f"Bearer {token}"}
            )
            
            if summary_response.status_code == 200:
                data = summary_response.json()
                if data.get('success'):
                    print("✅ AI summary generated successfully")
                    print(f"   Summary length: {len(data.get('ai_summary', ''))}")
                else:
                    print(f"❌ AI summary failed: {data.get('message')}")
            else:
                print(f"❌ AI summary request failed: {summary_response.status_code}")
                print(f"   Response: {summary_response.text}")
        else:
            print(f"❌ Authentication failed: {login_response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ AI summary error: {e}")
        return False
    
    print("\n🎉 All tests passed!")
    return True

if __name__ == "__main__":
    test_ai_summary_endpoint()
```

## 📋 **Render Environment Variables Checklist**

Ensure these are set in Render Dashboard → Environment:

```
OPENAI_API_KEY=sk-proj-your-actual-openai-key-here
MONGODB_URI=your-mongodb-connection-string
JWT_SECRET_KEY=your-jwt-secret-key
PORT=5000
```

## 🔍 **Check Render Logs**

1. Go to Render Dashboard
2. Click on your service
3. Click "Logs" tab
4. Look for OpenAI-related errors:
   - `❌ OpenAI API key not found`
   - `❌ OpenAI API call failed`
   - `❌ Failed to generate AI summary`

## 🚀 **Quick Fix Steps**

### **If OpenAI API Key is Missing:**
1. Get API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Set in Render: Dashboard → Environment → `OPENAI_API_KEY`
3. Redeploy service

### **If OpenAI API is Failing:**
1. Check [OpenAI Billing](https://platform.openai.com/account/billing)
2. Verify account status and credits
3. Test API key directly on OpenAI platform

### **If Still Failing:**
1. Check Render logs for specific errors
2. Test with the debugging script above
3. Verify all environment variables are set
4. Contact support if needed

## 📞 **Support Resources**

- **OpenAI Support:** [OpenAI Help Center](https://help.openai.com/)
- **Render Support:** [Render Documentation](https://render.com/docs)
- **Check Logs:** Always check Render service logs first

---

**Next Steps:** Run the debugging tests above and check Render logs to identify the specific issue with your AI summary endpoint.
