# OTP Email Troubleshooting Guide

## 🚨 **Issue: User Not Receiving OTP Email**

**Status:** Email service is working perfectly, but user may not be receiving emails.

## ✅ **What's Working:**

### **1. Email Service Status:**
- ✅ **Gmail SMTP:** Connected successfully
- ✅ **Authentication:** Working with app password
- ✅ **Email Sending:** `{'success': True, 'message': 'Email sent successfully'}`
- ✅ **OTP Generation:** Working correctly

### **2. Email Content:**
```
Subject: Patient Alert System - OTP Verification

Hello!

Your OTP for Patient Alert System is: 123456

This OTP is valid for 10 minutes.

If you didn't request this, please ignore this email.

Best regards,
Patient Alert System Team
```

### **3. Backend Logs:**
```
✅ Email sent successfully
✅ OTP email sent to: srinivasan.balakrishnan.lm@gmail.com
📧 Check your email in 1-2 minutes
✅ Primary email method successful
```

## 🔍 **Troubleshooting Steps:**

### **Step 1: Check Email Address**
- **Verify:** `srinivasan.balakrishnan.lm@gmail.com`
- **Check:** Is this the correct email address?
- **Test:** Try with a different email address

### **Step 2: Check Email Folders**
1. **Inbox:** Check main inbox
2. **Spam/Junk:** Check spam folder
3. **Promotions:** Check Gmail promotions tab
4. **All Mail:** Search for "Patient Alert System"

### **Step 3: Check Email Filters**
- **Gmail Filters:** Check if emails are being filtered
- **Blocked Senders:** Check if sender is blocked
- **Forwarding:** Check if emails are being forwarded

### **Step 4: Test with Different Email**
```bash
# Test with a different email address
curl -X POST http://localhost:5000/doctor-send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"your-other-email@gmail.com","purpose":"signup"}'
```

## 🔧 **Immediate Solutions:**

### **Solution 1: Check Spam Folder**
1. Go to Gmail
2. Click on "Spam" folder
3. Look for emails from `ramya.sureshkumar.lm@gmail.com`
4. Mark as "Not Spam" if found

### **Solution 2: Add Sender to Contacts**
1. Add `ramya.sureshkumar.lm@gmail.com` to contacts
2. This prevents future emails from going to spam

### **Solution 3: Check Gmail Settings**
1. Go to Gmail Settings
2. Check "Filters and Blocked Addresses"
3. Look for any filters blocking the sender

### **Solution 4: Use Different Email Provider**
Try with a different email provider:
- Yahoo Mail
- Outlook
- Other Gmail account

## 🧪 **Test Commands:**

### **Test 1: Send OTP to Different Email**
```bash
curl -X POST http://localhost:5000/doctor-send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@gmail.com","purpose":"signup"}'
```

### **Test 2: Check Email Service Directly**
```bash
python -c "from services.email_service import EmailService; es = EmailService(); result = es.send_otp_email('your-email@gmail.com', '123456'); print(result)"
```

### **Test 3: Verify OTP in Response**
The API response includes the OTP for testing:
```json
{
  "success": true,
  "otp": "123456",
  "jwt_token": "...",
  "message": "OTP sent successfully for signup verification"
}
```

## 📧 **Email Delivery Issues:**

### **Common Causes:**
1. **Spam Filter:** Email caught by spam filter
2. **Wrong Email:** Incorrect email address
3. **Email Provider:** Some providers block automated emails
4. **Network Issues:** Temporary delivery problems
5. **Gmail Security:** Gmail blocking automated emails

### **Gmail Specific Issues:**
- **App Passwords:** Make sure app password is correct
- **2FA:** Two-factor authentication must be enabled
- **Less Secure Apps:** Should be disabled (use app passwords)

## 🚀 **Alternative Solutions:**

### **Option 1: Use API Response OTP**
The API response includes the OTP for immediate use:
```json
{
  "otp": "123456"
}
```

### **Option 2: Add OTP to Response Message**
Modify the response to include OTP in the message:
```json
{
  "message": "OTP sent successfully. Your OTP is: 123456"
}
```

### **Option 3: Add Debug Endpoint**
Create an endpoint to get OTP without sending email:
```python
@app.route('/debug/get-otp/<email>', methods=['GET'])
def get_otp_debug(email):
    # Return OTP without sending email
    pass
```

## 📊 **Current Status:**

- ✅ **Email Service:** Working perfectly
- ✅ **OTP Generation:** Working correctly
- ✅ **API Response:** Includes OTP
- ❓ **Email Delivery:** May be going to spam
- ✅ **Backend Logs:** Show successful sending

## 🎯 **Next Steps:**

1. **Check spam folder** in Gmail
2. **Add sender to contacts** to prevent spam
3. **Try different email address** for testing
4. **Use OTP from API response** for immediate testing
5. **Check Gmail filters** and settings

**The email service is working perfectly. The issue is likely that emails are going to spam or being filtered by Gmail.** 📧
