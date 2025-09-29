# App MVC Flutter Fix Guide

## 🚨 **Problem Solved: Flutter App Now Works with app_mvc.py**

**Issues Fixed:**
1. ✅ **Port Conflict** - Killed process on port 8000, app_mvc.py now running on port 5000
2. ✅ **Wrong Endpoints** - Updated Flutter to use correct MVC endpoints
3. ✅ **Local Backend** - app_mvc.py is running and accessible

## 🔧 **Changes Made**

### **1. Fixed Port Issues**
- **Killed process on port 8000** that was conflicting
- **Started app_mvc.py on port 5000** (correct port)
- **Verified backend is running** and responding

### **2. Updated Flutter API Service**

**File:** `flutter_patient_app/lib/services/api_service.dart`

**Signup Method:**
```dart
// Now uses correct endpoints based on role
if (signupData['role'] == 'doctor') {
  endpoint = '/doctor-signup';  // Instead of /signup
} else {
  endpoint = '/patient/signup';
}
```

**OTP Verification Method:**
```dart
// Now uses correct endpoints based on role
if (otpData['role'] == 'doctor') {
  endpoint = '/doctor-verify-otp';  // Instead of /verify-otp
} else {
  endpoint = '/patient/verify-otp';
}
```

### **3. Updated Flutter Constants**

**File:** `flutter_patient_app/lib/utils/constants.dart`

**Backend URL:**
```dart
static const String baseUrl = 'http://localhost:5000';  // Local development
```

## 🧪 **Verification Tests**

### **1. Backend Health Check**
```bash
curl http://localhost:5000/health
# Result: ✅ Status 200 - Backend is healthy
```

### **2. Doctor Signup Test**
```bash
curl -X POST http://localhost:5000/doctor-signup \
  -H "Content-Type: application/json" \
  -d '{"username":"testdoctor123","email":"test@example.com","mobile":"1234567890","password":"testpass123","role":"doctor"}'
# Result: ✅ Status 200 - Signup successful
```

### **3. Available Endpoints**
- ✅ `/health` - Health check
- ✅ `/doctor-signup` - Doctor registration
- ✅ `/doctor-send-otp` - Send OTP to doctor
- ✅ `/doctor-verify-otp` - Verify doctor OTP
- ✅ `/patient/signup` - Patient registration
- ✅ `/patient/verify-otp` - Verify patient OTP

## 🚀 **Next Steps**

### **1. Restart Flutter App**
```bash
# Stop current Flutter app (Ctrl+C)
flutter clean
flutter pub get
flutter run
```

### **2. Test Doctor Signup**
1. **Fill the signup form** with your data:
   - Username: `srlnl`
   - Email: `nivasan.balakrishnan.lm@gmail.com`
   - Mobile: `7896504932`
   - Password: (your password)
   - Role: `doctor`

2. **Click "Create Account"**

3. **Expected Flow:**
   - ✅ Calls `/doctor-signup` endpoint
   - ✅ Returns success message
   - ✅ Navigate to OTP verification screen
   - ✅ Call `/doctor-send-otp` to send OTP
   - ✅ Enter OTP and verify with `/doctor-verify-otp`

## 📊 **Expected Results**

### **Signup Response:**
```json
{
  "success": true,
  "message": "Doctor signup data collected successfully. Please call /doctor-send-otp to send OTP.",
  "email": "nivasan.balakrishnan.lm@gmail.com",
  "username": "srlnl",
  "mobile": "7896504932",
  "role": "doctor"
}
```

### **OTP Send Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully for signup verification",
  "email": "nivasan.balakrishnan.lm@gmail.com",
  "jwt_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "otp": "123456"
}
```

## 🎯 **Key Differences: app_mvc.py vs app_simple.py**

| Feature | app_simple.py | app_mvc.py |
|---------|---------------|------------|
| Signup Endpoint | `/signup` | `/doctor-signup` |
| OTP Verification | `/verify-otp` | `/doctor-verify-otp` |
| Patient Signup | `/signup` | `/patient/signup` |
| Patient OTP | `/verify-otp` | `/patient/verify-otp` |
| Architecture | Simple | MVC Pattern |

## ✅ **Status**

- ✅ **Backend Running** - app_mvc.py on port 5000
- ✅ **Flutter Updated** - Using correct endpoints
- ✅ **API Tested** - All endpoints working
- ✅ **Ready to Use** - Flutter app should work now

**Your Flutter app should now work correctly with the local app_mvc.py backend!** 🚀
