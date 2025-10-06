#!/usr/bin/env python3
"""
Test script for forgot password functionality
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_doctor_forgot_password():
    """Test doctor forgot password endpoint"""
    print("🧪 Testing Doctor Forgot Password...")
    
    # Test data
    email = "dr.john.smith@example.com"
    
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
            print(f"❌ Doctor forgot password failed: {response.json()}")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_doctor_reset_password(jwt_token, otp):
    """Test doctor reset password endpoint"""
    print("\n🧪 Testing Doctor Reset Password...")
    
    # Test data
    email = "dr.john.smith@example.com"
    new_password = "NewSecurePass123!"
    
    # Test reset password
    url = f"{BASE_URL}/doctor-reset-password"
    data = {
        "email": email,
        "otp": otp,
        "jwt_token": jwt_token,
        "new_password": new_password
    }
    
    print(f"📤 Sending request to: {url}")
    print(f"📤 Data: {json.dumps(data, indent=2)}")
    
    try:
        response = requests.post(url, json=data)
        print(f"📥 Status Code: {response.status_code}")
        print(f"📥 Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Doctor reset password successful")
            return response.json()
        else:
            print(f"❌ Doctor reset password failed: {response.json()}")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_generic_reset_password(jwt_token, otp):
    """Test generic reset password endpoint"""
    print("\n🧪 Testing Generic Reset Password...")
    
    # Test data
    email = "dr.john.smith@example.com"
    new_password = "NewSecurePass456!"
    role = "doctor"
    
    # Test reset password
    url = f"{BASE_URL}/reset-password"
    data = {
        "email": email,
        "otp": otp,
        "jwt_token": jwt_token,
        "new_password": new_password,
        "role": role
    }
    
    print(f"📤 Sending request to: {url}")
    print(f"📤 Data: {json.dumps(data, indent=2)}")
    
    try:
        response = requests.post(url, json=data)
        print(f"📥 Status Code: {response.status_code}")
        print(f"📥 Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Generic reset password successful")
            return response.json()
        else:
            print(f"❌ Generic reset password failed: {response.json()}")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

if __name__ == "__main__":
    print("🚀 Starting Forgot Password Tests...")
    
    # Test forgot password
    forgot_result = test_doctor_forgot_password()
    
    if forgot_result and 'jwt_token' in forgot_result and 'otp' in forgot_result:
        jwt_token = forgot_result['jwt_token']
        otp = forgot_result['otp']
        
        print(f"\n🔑 JWT Token: {jwt_token[:50]}...")
        print(f"🔑 OTP: {otp}")
        
        # Test reset password
        test_doctor_reset_password(jwt_token, otp)
        
        # Test generic reset password
        test_generic_reset_password(jwt_token, otp)
    else:
        print("❌ Forgot password test failed, skipping reset password tests")
    
    print("\n🏁 Tests completed!")
