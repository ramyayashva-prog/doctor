#!/usr/bin/env python3
"""
Test what Flutter app should send for OTP verification
"""

import requests
import json

def test_flutter_otp_request():
    """Test the exact request that Flutter app should make"""
    print("🧪 Testing Flutter OTP Request Format")
    print("=" * 50)
    
    # This is what Flutter app should send
    flutter_request = {
        "email": "srinivasan.balakrishnan.lm@gmail.com",
        "otp": "883779",
        "role": "doctor",
        "jwt_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJvdHAiOiI4ODM3NzkiLCJlbWFpbCI6InNyaW5pdmFzYW4uYmFsYWtyaXNobmFuLmxtQGdtYWlsLmNvbSIsInB1cnBvc2UiOiJkb2N0b3Jfc2lnbnVwIiwiYXR0ZW1wdHMiOjAsIm1heF9hdHRlbXB0cyI6MywianRpIjoiUktRaFhfWFBwNzRBd1o0MFY1RXRKZk9iWkYxREt0X3ZRMUVudDRlUDlMcyIsImlhdCI6MTc1OTEzNjIxMiwiZXhwIjoxNzU5MTM4MDEyLCJ0eXBlIjoib3RwX3Rva2VuIiwic2lnbnVwX2RhdGEiOnsidXNlcm5hbWUiOiJzcmluaSIsImVtYWlsIjoic3Jpbml2YXNhbi5iYWxha3Jpc2huYW4ubG1AZ21haWwuY29tIiwibW9iaWxlIjoiNzg0NTY5NTk0MiIsInBhc3N3b3JkIjoiU3JpbmlAMSIsInJvbGUiOiJkb2N0b3IifX0.AFGl5oMY8nk-JKfCVZyzVaB09wWE8Nlb9IacusHacmA"
    }
    
    print("📱 Flutter Request Format:")
    print(json.dumps(flutter_request, indent=2))
    
    print("\n🔍 Testing with backend...")
    
    try:
        response = requests.post(
            "http://localhost:5000/doctor-verify-otp",
            headers={"Content-Type": "application/json"},
            json=flutter_request
        )
        
        print(f"📊 Response Status: {response.status_code}")
        print(f"📊 Response Body: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ OTP verification successful!")
            print(f"   Doctor ID: {result.get('doctor_id')}")
            print(f"   Username: {result.get('username')}")
            print(f"   Status: {result.get('status')}")
        else:
            print("❌ OTP verification failed")
            
    except Exception as e:
        print(f"❌ Request failed: {e}")

if __name__ == "__main__":
    test_flutter_otp_request()
