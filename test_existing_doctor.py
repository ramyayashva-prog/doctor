#!/usr/bin/env python3
"""
Test script to check existing doctors and test forgot password
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("🧪 Testing Health Endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"📥 Health Status: {response.status_code}")
        print(f"📥 Health Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_doctor_signup():
    """Test doctor signup to create a test doctor"""
    print("\n🧪 Testing Doctor Signup...")
    
    # Test data
    signup_data = {
        "username": "TestDoctor",
        "email": "test.doctor@example.com",
        "mobile": "9876543210",
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
            return signup_data['email']
        else:
            print(f"❌ Doctor signup failed")
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

if __name__ == "__main__":
    print("🚀 Starting Doctor Forgot Password Tests...")
    
    # Test health first
    if not test_health():
        print("❌ Server not healthy, stopping tests")
        exit(1)
    
    # Try to signup a test doctor
    test_email = test_doctor_signup()
    
    if test_email:
        # Test forgot password with the created doctor
        forgot_result = test_doctor_forgot_password(test_email)
        
        if forgot_result and 'jwt_token' in forgot_result and 'otp' in forgot_result:
            print(f"\n🔑 JWT Token: {forgot_result['jwt_token'][:50]}...")
            print(f"🔑 OTP: {forgot_result['otp']}")
            print("✅ Forgot password flow working correctly!")
        else:
            print("❌ Forgot password flow failed")
    else:
        print("❌ Could not create test doctor, trying with existing email")
        # Try with a common test email
        test_doctor_forgot_password("dr.test@example.com")
    
    print("\n🏁 Tests completed!")
