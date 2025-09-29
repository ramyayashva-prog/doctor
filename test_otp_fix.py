#!/usr/bin/env python3
"""
Test OTP Fix - Verify Flutter app handles OTP response correctly
"""

import requests
import json

def test_otp_response():
    """Test that OTP response is handled correctly even with email failure"""
    print("🧪 Testing OTP Response Handling")
    print("=" * 50)
    
    # Test doctor signup first
    print("1️⃣ Testing Doctor Signup...")
    signup_data = {
        "username": "testdoctor3",
        "email": "srinivasan.balakrishnan.lm@gmail.com",
        "mobile": "1234567890",
        "password": "test123",
        "role": "doctor"
    }
    
    try:
        signup_response = requests.post(
            "http://localhost:5000/doctor-signup",
            headers={"Content-Type": "application/json"},
            json=signup_data
        )
        
        if signup_response.status_code == 200:
            print("✅ Doctor signup successful")
            signup_result = signup_response.json()
            print(f"   Response: {json.dumps(signup_result, indent=2)}")
        else:
            print(f"❌ Doctor signup failed: {signup_response.status_code}")
            print(f"   Error: {signup_response.text}")
            return
    except Exception as e:
        print(f"❌ Signup request failed: {e}")
        return
    
    # Test OTP sending
    print("\n2️⃣ Testing OTP Sending...")
    otp_data = {
        "email": "srinivasan.balakrishnan.lm@gmail.com",
        "purpose": "signup"
    }
    
    try:
        otp_response = requests.post(
            "http://localhost:5000/doctor-send-otp",
            headers={"Content-Type": "application/json"},
            json=otp_data
        )
        
        print(f"📊 OTP Response Status: {otp_response.status_code}")
        otp_result = otp_response.json()
        print(f"📊 OTP Response: {json.dumps(otp_result, indent=2)}")
        
        # Check if OTP and JWT token are available
        if 'otp' in otp_result and 'jwt_token' in otp_result:
            print("✅ OTP and JWT token are available")
            print(f"   OTP: {otp_result['otp']}")
            print(f"   JWT Token Length: {len(otp_result['jwt_token'])}")
            print(f"   JWT Token Preview: {otp_result['jwt_token'][:50]}...")
            
            if 'error' in otp_result:
                print("⚠️ Email sending failed, but OTP is available")
                print(f"   Error: {otp_result['error']}")
                print("✅ This should be treated as SUCCESS by Flutter app")
            else:
                print("✅ Email sending successful")
        else:
            print("❌ OTP or JWT token missing - this is a real failure")
            
    except Exception as e:
        print(f"❌ OTP request failed: {e}")

if __name__ == "__main__":
    test_otp_response()
