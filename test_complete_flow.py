#!/usr/bin/env python3
"""
Test complete authentication flow including forgot password
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_doctor_signup():
    """Test doctor signup to create a test doctor"""
    print("🧪 Testing Doctor Signup...")
    
    # Test data
    signup_data = {
        "username": "TestDoctor2",
        "email": "test.doctor2@example.com",
        "mobile": "9876543211",
        "password": "TestPass123!",
        "role": "doctor"
    }
    
    print(f"📤 Sending signup request...")
    print(f"📤 Data: {json.dumps(signup_data, indent=2)}")
    
    try:
        response = requests.post(f"{BASE_URL}/doctor-signup", json=signup_data)
        print(f"📥 Status Code: {response.status_code}")
        print(f"📥 Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Doctor signup successful")
            return response.json()
        else:
            print(f"❌ Doctor signup failed")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_doctor_verify_otp(email, otp, jwt_token):
    """Test doctor OTP verification"""
    print(f"\n🧪 Testing Doctor OTP Verification...")
    
    # Test data
    verify_data = {
        "email": email,
        "otp": otp,
        "jwt_token": jwt_token,
        "role": "doctor"
    }
    
    print(f"📤 Sending OTP verification request...")
    print(f"📤 Data: {json.dumps(verify_data, indent=2)}")
    
    try:
        response = requests.post(f"{BASE_URL}/doctor-verify-otp", json=verify_data)
        print(f"📥 Status Code: {response.status_code}")
        print(f"📥 Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Doctor OTP verification successful")
            return response.json()
        else:
            print(f"❌ Doctor OTP verification failed")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_doctor_forgot_password(email):
    """Test doctor forgot password endpoint"""
    print(f"\n🧪 Testing Doctor Forgot Password for {email}...")
    
    # Test forgot password
    url = f"{BASE_URL}/doctor-forgot-password"
    data = {
        "email": email
    }
    
    print(f"📤 Sending request to: {url}")
    print(f"📤 Data: {json.dumps(data, indent=2)}")
    
    try:
        response = requests.post(url, json=data)
        print(f"📥 Status Code: {response.status_code}")
        print(f"📥 Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Doctor forgot password successful")
            return response.json()
        else:
            print(f"❌ Doctor forgot password failed")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_doctor_reset_password(email, otp, jwt_token):
    """Test doctor reset password"""
    print(f"\n🧪 Testing Doctor Reset Password...")
    
    # Test data
    reset_data = {
        "email": email,
        "otp": otp,
        "jwt_token": jwt_token,
        "new_password": "NewTestPass123!"
    }
    
    print(f"📤 Sending reset password request...")
    print(f"📤 Data: {json.dumps(reset_data, indent=2)}")
    
    try:
        response = requests.post(f"{BASE_URL}/doctor-reset-password", json=reset_data)
        print(f"📥 Status Code: {response.status_code}")
        print(f"📥 Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Doctor reset password successful")
            return response.json()
        else:
            print(f"❌ Doctor reset password failed")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

if __name__ == "__main__":
    print("🚀 Starting Complete Authentication Flow Tests...")
    
    # Step 1: Doctor signup
    signup_result = test_doctor_signup()
    
    if signup_result and 'signup_token' in signup_result and 'otp' in signup_result:
        email = signup_result['email']
        jwt_token = signup_result['signup_token']
        otp = signup_result['otp']
        
        print(f"\n🔑 Email: {email}")
        print(f"🔑 OTP: {otp}")
        print(f"🔑 JWT Token: {jwt_token[:50]}...")
        
        # Step 2: Verify OTP to create doctor in database
        verify_result = test_doctor_verify_otp(email, otp, jwt_token)
        
        if verify_result:
            print("✅ Doctor account created in database")
            
            # Step 3: Test forgot password (should work now)
            forgot_result = test_doctor_forgot_password(email)
            
            if forgot_result and 'jwt_token' in forgot_result and 'otp' in forgot_result:
                reset_jwt_token = forgot_result['jwt_token']
                reset_otp = forgot_result['otp']
                
                print(f"\n🔑 Reset OTP: {reset_otp}")
                print(f"🔑 Reset JWT Token: {reset_jwt_token[:50]}...")
                
                # Step 4: Test reset password
                reset_result = test_doctor_reset_password(email, reset_otp, reset_jwt_token)
                
                if reset_result:
                    print("✅ Complete forgot password flow successful!")
                else:
                    print("❌ Reset password failed")
            else:
                print("❌ Forgot password failed")
        else:
            print("❌ OTP verification failed")
    else:
        print("❌ Doctor signup failed")
    
    print("\n🏁 Complete flow tests finished!")
