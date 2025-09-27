#!/usr/bin/env python3
"""
Test login functionality
"""

import requests
import json

def test_login():
    """Test the login endpoint"""
    
    base_url = "http://localhost:5000"
    
    # Your credentials
    login_data = {
        "email": "ramyayashva@gmail.com",
        "password": "Ramya@1"
    }
    
    print("🔐 Testing Doctor Login")
    print("=" * 30)
    print(f"Email: {login_data['email']}")
    print(f"Password: {login_data['password']}")
    print()
    
    try:
        response = requests.post(
            f"{base_url}/doctor-login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print("\n🎉 LOGIN SUCCESSFUL!")
            print(f"✅ Doctor ID: {data.get('doctor_id', 'N/A')}")
            print(f"✅ Username: {data.get('username', 'N/A')}")
            print(f"✅ Token: {data.get('token', 'N/A')[:20]}...")
            return True
        else:
            print("\n❌ LOGIN FAILED!")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Testing Doctor Login")
    print("Make sure your server is running on http://localhost:5000")
    print()
    
    success = test_login()
    
    if success:
        print("\n✅ Authentication is working correctly!")
        print("You can now deploy to Render with confidence.")
    else:
        print("\n❌ Authentication is still failing!")
        print("Please check the server logs for more details.")
