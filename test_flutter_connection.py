#!/usr/bin/env python3
"""
Test Flutter App Connection to Backend
"""

import requests
import json

def test_backend_connection():
    """Test if the backend is accessible from Flutter app"""
    print("🧪 Testing Flutter App Connection to Backend")
    print("=" * 50)
    
    # Test the production URL that Flutter will use
    base_url = "https://doctor-9don.onrender.com"
    
    # Test endpoints that Flutter app uses
    endpoints = [
        "/health",
        "/signup", 
        "/doctor-send-otp",
        "/verify-otp"
    ]
    
    print(f"🌐 Testing backend at: {base_url}")
    print()
    
    for endpoint in endpoints:
        url = f"{base_url}{endpoint}"
        print(f"🔍 Testing: {endpoint}")
        
        try:
            if endpoint == "/health":
                # GET request for health check
                response = requests.get(url, timeout=10)
            else:
                # POST request for other endpoints (with minimal data)
                test_data = {
                    "email": "test@example.com",
                    "username": "testuser",
                    "mobile": "1234567890",
                    "password": "testpass123",
                    "role": "doctor"
                }
                response = requests.post(
                    url, 
                    headers={"Content-Type": "application/json"},
                    json=test_data,
                    timeout=10
                )
            
            print(f"   Status: {response.status_code}")
            
            if response.status_code in [200, 400, 404]:  # 400/404 are expected for test data
                print(f"   ✅ Endpoint accessible")
            else:
                print(f"   ⚠️ Unexpected status: {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print(f"   ❌ Connection failed - Backend not accessible")
        except requests.exceptions.Timeout:
            print(f"   ❌ Timeout - Backend too slow")
        except Exception as e:
            print(f"   ❌ Error: {e}")
        
        print()
    
    print("🎯 Summary:")
    print("If all endpoints show '✅ Endpoint accessible', the Flutter app should work.")
    print("If you see '❌ Connection failed', check if the backend is running on Render.")

if __name__ == "__main__":
    test_backend_connection()
