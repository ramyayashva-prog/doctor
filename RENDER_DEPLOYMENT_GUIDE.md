# Render Deployment Guide

## 🚀 Quick Fix for Current Error

The error you're seeing is due to missing `setuptools` and incompatible dependencies. Here's how to fix it:

### **Step 1: Use the Fixed Files**

I've created these files for you:

1. **`runtime.txt`** - Set to Python 3.11.10 (stable for Render)
2. **`requirements-minimal.txt`** - Minimal dependencies for deployment
3. **`render.yaml`** - Render configuration file

### **Step 2: Update Your Render Service**

#### **Option A: Use render.yaml (Recommended)**
1. In your Render dashboard, go to your service
2. Delete the current service
3. Create a new service using the `render.yaml` file:
   - Click "New" → "Blueprint"
   - Connect your GitHub repository
   - Render will automatically detect `render.yaml`

#### **Option B: Manual Configuration**
1. In your Render service settings:
   - **Build Command**: `pip install --upgrade pip && pip install -r requirements-minimal.txt`
   - **Start Command**: `gunicorn --bind 0.0.0.0:$PORT app_mvc:app`
   - **Python Version**: 3.11.10

### **Step 3: Environment Variables**

Set these in your Render service:

```bash
PORT=5000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET_KEY=your_jwt_secret_key
OPENAI_API_KEY=your_openai_api_key
```

## 🔧 **What I Fixed:**

### **1. Runtime Configuration**
- **Before**: Empty `runtime.txt`
- **After**: `python-3.11.10` (stable version for Render)

### **2. Dependencies**
- **Removed problematic packages**: `google-cloud-speech`, `elevenlabs`, `python-magic`
- **Added build tools**: `setuptools>=65.0.0`, `wheel>=0.40.0`
- **Simplified audio dependencies**: Kept only essential ones

### **3. Build Configuration**
- **Added proper build command** with pip upgrade
- **Set correct start command** for Gunicorn
- **Added health check** endpoint

## 📋 **Deployment Steps:**

### **Method 1: Using render.yaml (Easiest)**
1. **Push changes** to your GitHub repository
2. **Connect Render** to your repo
3. **Select "Blueprint"** option
4. **Render auto-detects** `render.yaml`
5. **Deploy** automatically

### **Method 2: Manual Setup**
1. **Create new web service** in Render
2. **Connect GitHub** repository
3. **Set build command**: `pip install --upgrade pip && pip install -r requirements-minimal.txt`
4. **Set start command**: `gunicorn --bind 0.0.0.0:$PORT app_mvc:app`
5. **Add environment variables**
6. **Deploy**

## 🗄️ **Database Setup:**

### **For MongoDB Atlas (Recommended)**
1. **Create MongoDB Atlas** account
2. **Create cluster** (free tier available)
3. **Get connection string**
4. **Set as MONGODB_URI** in Render environment variables

### **For Render Database (Alternative)**
1. **Create database** in Render dashboard
2. **Use connection string** from Render database
3. **Set as MONGODB_URI** in environment variables

## 🔑 **Required Environment Variables:**

```bash
# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/doctor_db

# Authentication
JWT_SECRET_KEY=your_super_secret_jwt_key_here

# OpenAI (for AI summaries) - REQUIRED FOR AI SUMMARY ENDPOINTS
OPENAI_API_KEY=sk-your_openai_api_key_here

# Server
PORT=5000
```

### **🚨 IMPORTANT: OpenAI API Key Setup**

If you're getting `"Failed to generate AI summary"` errors, you need to configure the OpenAI API key:

#### **Step 1: Get OpenAI API Key**
1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create a new API key
3. Copy the key (starts with `sk-`)

#### **Step 2: Configure in Render Dashboard**
1. **Go to your Render service dashboard**
2. **Click "Environment" tab**
3. **Find `OPENAI_API_KEY` in the list**
4. **Click "Edit" and paste your API key**
5. **Click "Save Changes"**
6. **Service will auto-redeploy**

#### **Step 3: Test AI Summary Endpoint**
```bash
# Test with your deployed URL
curl -X GET "https://your-app-name.onrender.com/doctor/patient/PATIENT_ID/ai-summary" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN"
```

## 🚨 **Common Issues & Solutions:**

### **1. "Failed to generate AI summary" Error**
- **Cause**: OpenAI API key not configured in Render environment variables
- **Solution**: 
  1. Go to Render Dashboard > Your Service > Environment
  2. Find `OPENAI_API_KEY` and set your OpenAI API key
  3. Redeploy the service
- **Test**: Use the AI Summary Postman collection to verify

### **2. Build Still Fails**
- **Solution**: Use `requirements-minimal.txt` instead of `requirements.txt`
- **Remove**: Any local file dependencies

### **3. Database Connection Error**
- **Check**: MongoDB URI format
- **Verify**: Network access in MongoDB Atlas
- **Test**: Connection string locally first

### **4. Import Errors**
- **Solution**: Ensure all imports are in the minimal requirements
- **Check**: No local file imports in your code

### **5. Port Issues**
- **Solution**: Use `$PORT` environment variable (Render sets this automatically)
- **Check**: Start command uses `0.0.0.0:$PORT`

### **6. OpenAI API Errors**
- **"Insufficient quota"**: Add payment method to OpenAI account
- **"Invalid API key"**: Verify API key format (starts with `sk-`)
- **"Rate limit exceeded"**: Implement request throttling

## 📝 **Testing Your Deployment:**

### **1. Health Check**
```bash
curl https://your-app-name.onrender.com/health
```

### **2. Test Login**
```bash
curl -X POST https://your-app-name.onrender.com/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ramyayashva@gmail.com","password":"password123"}'
```

### **3. Test Patient Creation**
```bash
curl -X POST https://your-app-name.onrender.com/patients \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Test Patient","date_of_birth":"01/01/1990","contact_number":"1234567890","email":"test@example.com"}'
```

## 🎯 **Next Steps:**

1. **Update your repository** with the new files
2. **Redeploy** on Render
3. **Test** the endpoints
4. **Set up** MongoDB database
5. **Configure** environment variables

## 📞 **If Still Having Issues:**

1. **Check Render logs** for specific error messages
2. **Verify** all environment variables are set
3. **Test** locally with the minimal requirements
4. **Use** the Postman collection to test endpoints

---

**Your deployment should work now! 🚀**
