#!/usr/bin/env python3
"""
Test script to debug local authentication issues
"""

import requests
import json

def test_local_endpoints():
    """Test all debug endpoints locally"""
    base_url = "http://localhost:5000"
    
    print("🔍 Testing Local Authentication Debug Endpoints")
    print("=" * 50)
    
    # Test 1: Environment Variables
    print("\n1️⃣ Testing Environment Variables...")
    try:
        response = requests.get(f"{base_url}/debug/env")
        if response.status_code == 200:
            data = response.json()
            print("✅ Environment Variables:")
            for key, value in data.items():
                print(f"   {key}: {value}")
        else:
            print(f"❌ Failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test 2: Database Connection
    print("\n2️⃣ Testing Database Connection...")
    try:
        response = requests.get(f"{base_url}/debug/db")
        if response.status_code == 200:
            data = response.json()
            print("✅ Database Status:")
            for key, value in data.items():
                print(f"   {key}: {value}")
        else:
            print(f"❌ Failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test 3: Doctor Data
    print("\n3️⃣ Testing Doctor Data...")
    try:
        response = requests.get(f"{base_url}/debug/doctors")
        if response.status_code == 200:
            data = response.json()
            print("✅ Doctor Data:")
            print(f"   Doctor Count: {data.get('doctor_count', 0)}")
            if data.get('doctors'):
                print("   Sample Doctors:")
                for doctor in data['doctors']:
                    print(f"     - {doctor.get('username', 'Unknown')} ({doctor.get('email', 'No email')})")
            else:
                print("   ⚠️  No doctors found in database!")
        else:
            print(f"❌ Failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Test 4: Test Login (you need to provide credentials)
    print("\n4️⃣ Testing Login (provide your credentials)...")
    email = input("Enter your doctor email: ").strip()
    password = input("Enter your password: ").strip()
    
    if email and password:
        try:
            response = requests.post(
                f"{base_url}/debug/test-login",
                json={"email": email, "password": password},
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 200:
                data = response.json()
                print("✅ Login Test Results:")
                for key, value in data.items():
                    print(f"   {key}: {value}")
            else:
                print(f"❌ Failed: {response.status_code}")
                print(f"Response: {response.text}")
        except Exception as e:
            print(f"❌ Error: {e}")
    else:
        print("⚠️  Skipping login test - no credentials provided")

def test_actual_login(email, password):
    """Test actual login endpoint"""
    base_url = "http://localhost:5000"
    
    print(f"\n🔐 Testing Actual Login for: {email}")
    try:
        response = requests.post(
            f"{base_url}/doctor-login",
            json={"email": email, "password": password},
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Login Successful!")
            print(f"   Doctor ID: {data.get('doctor_id', 'N/A')}")
            print(f"   Username: {data.get('username', 'N/A')}")
            print(f"   Token: {data.get('token', 'N/A')[:20]}...")
        else:
            print("❌ Login Failed!")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("🚀 Starting Local Authentication Debug Test")
    print("Make sure your local server is running on http://localhost:5000")
    print()
    
    # Test debug endpoints
    test_local_endpoints()
    
    # Test actual login if credentials provided
    print("\n" + "="*50)
    print("🔐 Testing Actual Login Endpoint")
    email = input("\nEnter your doctor email for login test: ").strip()
    password = input("Enter your password: ").strip()
    
    if email and password:
        test_actual_login(email, password)
    else:
        print("⚠️  Skipping actual login test")
    
    print("\n✅ Debug test completed!")
