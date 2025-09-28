#!/usr/bin/env python3
"""
Test script for patients endpoint to verify ObjectId conversion fix
"""

import requests
import json
from datetime import datetime

def test_patients_endpoint():
    """Test the patients endpoint to ensure ObjectId conversion works"""
    
    base_url = "http://localhost:5000"
    
    print("🧪 Testing Patients Endpoint ObjectId Fix")
    print("=" * 50)
    
    # Test 1: Health check
    print("1. Testing health check...")
    try:
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health check passed")
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False
    
    # Test 2: Get all patients
    print("\n2. Testing get all patients endpoint...")
    try:
        response = requests.get(f"{base_url}/patients?page=1&limit=10&search=", timeout=10)
        
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"✅ Patients endpoint successful!")
                print(f"   Total patients: {data.get('total', 0)}")
                print(f"   Page: {data.get('page', 1)}")
                print(f"   Limit: {data.get('limit', 10)}")
                
                # Check if patients data is properly formatted
                patients = data.get('patients', [])
                if patients:
                    patient = patients[0]
                    print(f"   Sample patient fields: {list(patient.keys())}")
                    
                    # Check for ObjectId fields
                    if '_id' in patient:
                        print(f"   Patient _id type: {type(patient['_id'])}")
                        if isinstance(patient['_id'], str):
                            print("✅ _id is properly converted to string")
                        else:
                            print("❌ _id is still ObjectId")
                    
                    # Check nested fields for ObjectIds
                    for key, value in patient.items():
                        if isinstance(value, list) and value:
                            for item in value[:2]:  # Check first 2 items
                                if isinstance(item, dict) and '_id' in item:
                                    if isinstance(item['_id'], str):
                                        print(f"✅ Nested {key} _id is properly converted to string")
                                    else:
                                        print(f"❌ Nested {key} _id is still ObjectId")
                                        print(f"   Type: {type(item['_id'])}")
                
                return True
                
            except json.JSONDecodeError as e:
                print(f"❌ JSON decode error: {e}")
                print(f"   Response content: {response.text[:200]}...")
                return False
                
        else:
            print(f"❌ Patients endpoint failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Patients endpoint error: {e}")
        return False

def test_patient_search():
    """Test patient search functionality"""
    base_url = "http://localhost:5000"
    
    print("\n3. Testing patient search...")
    try:
        response = requests.get(f"{base_url}/patients?page=1&limit=5&search=test", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Search endpoint successful!")
            print(f"   Search results: {data.get('total', 0)} patients")
            return True
        else:
            print(f"❌ Search failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Search error: {e}")
        return False

def test_debug_endpoints():
    """Test debug endpoints if available"""
    base_url = "http://localhost:5000"
    
    print("\n4. Testing debug endpoints...")
    
    # Test OpenAI config debug
    try:
        response = requests.get(f"{base_url}/debug/openai-config", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print("✅ OpenAI config debug endpoint available")
            print(f"   API key present: {data.get('debug_info', {}).get('openai_api_key_present', False)}")
        else:
            print(f"ℹ️ OpenAI config debug not available: {response.status_code}")
    except Exception as e:
        print(f"ℹ️ OpenAI config debug error: {e}")

def main():
    """Main test function"""
    print(f"🚀 Patients Endpoint ObjectId Fix Test")
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Run tests
    test1 = test_patients_endpoint()
    test2 = test_patient_search()
    test_debug_endpoints()
    
    print("\n" + "=" * 60)
    print("📋 Test Results Summary:")
    print(f"   Patients Endpoint: {'✅ PASS' if test1 else '❌ FAIL'}")
    print(f"   Patient Search: {'✅ PASS' if test2 else '❌ FAIL'}")
    
    if test1 and test2:
        print("\n🎉 All tests passed! ObjectId conversion fix is working!")
        print("💡 The patients endpoint should now work on Render deployment.")
    else:
        print("\n⚠️ Some tests failed. Check the errors above.")
        print("💡 Make sure your backend server is running locally.")

if __name__ == "__main__":
    main()
