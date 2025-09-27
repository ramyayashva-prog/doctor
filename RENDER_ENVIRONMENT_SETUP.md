# Render Environment Variables Setup

## Required Environment Variables for Render Deployment

Add these environment variables in your Render dashboard:

### 1. MongoDB Configuration
```
MONGODB_URI=mongodb+srv://ramya:XxFn6n0NXx0wBplV@cluster0.c1g1bm5.mongodb.net
DATABASE_NAME=patients_db
```

### 2. Email Configuration
```
SENDER_EMAIL=ramya.sureshkumar.lm@gmail.com
SENDER_PASSWORD=djqs dktf gqor gnqg
```

### 3. JWT Configuration
```
JWT_SECRET_KEY=27982af8380786e1f2967dca145cc0ed
JWT_ALGORITHM=HS256
```

## How to Add Environment Variables in Render:

1. Go to your Render dashboard
2. Select your service
3. Go to "Environment" tab
4. Add each variable above
5. Click "Save Changes"
6. Redeploy your service

## Verification Steps:

1. Check Render logs for connection errors
2. Verify MongoDB Atlas allows connections from Render IPs
3. Test database connection with a simple endpoint
