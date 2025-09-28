#!/usr/bin/env python3
"""
Test script for Render deployment verification
Tests all endpoints on https://doctor-9don.onrender.com
"""

import requests
import json
from datetime import datetime

def test_endpoint(url, method="GET", data=None, headers=None, description=""):
    """Test a single endpoint and return results"""
    try:
        if method == "GET":
            response = requests.get(url, timeout=10, headers=headers)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=10, headers=headers)
        
        return {
            "url": url,
            "method": method,
            "status_code": response.status_code,
            "success": response.status_code < 400,
            "description": description,
            "response": response.json() if response.headers.get('content-type', '').startswith('application/json') else response.text[:200],
            "error": None
        }
    except Exception as e:
        return {
            "url": url,
            "method": method,
            "status_code": None,
            "success": False,
            "description": description,
            "response": None,
            "error": str(e)
        }

def main():
    """Test all endpoints on Render deployment"""
    base_url = "https://doctor-9don.onrender.com"
    
    print("🧪 Testing Render Deployment")
    print(f"🌐 Base URL: {base_url}")
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Test endpoints
    tests = [
        {
            "url": f"{base_url}/",
            "method": "GET",
            "description": "Root endpoint"
        },
        {
            "url": f"{base_url}/health",
            "method": "GET", 
            "description": "Health check"
        },
        {
            "url": f"{base_url}/patients?page=1&limit=5&search=",
            "method": "GET",
            "description": "Patients list (ObjectId fix test)"
        },
        {
            "url": f"{base_url}/patients?page=1&limit=3&search=test",
            "method": "GET",
            "description": "Patient search"
        },
        {
            "url": f"{base_url}/debug/openai-config",
            "method": "GET",
            "description": "OpenAI configuration debug"
        },
        {
            "url": f"{base_url}/debug/test-openai",
            "method": "GET",
            "description": "OpenAI API test"
        }
    ]
    
    results = []
    
    for test in tests:
        print(f"\n🔍 Testing: {test['description']}")
        print(f"   URL: {test['url']}")
        
        result = test_endpoint(
            test['url'], 
            test['method'], 
            test.get('data'),
            test.get('headers'),
            test['description']
        )
        
        results.append(result)
        
        if result['success']:
            print(f"   ✅ Status: {result['status_code']} - SUCCESS")
            if result['response'] and isinstance(result['response'], dict):
                # Show key information from response
                if 'status' in result['response']:
                    print(f"   📊 Status: {result['response']['status']}")
                if 'total' in result['response']:
                    print(f"   📊 Total: {result['response']['total']}")
                if 'patients' in result['response']:
                    print(f"   📊 Patients: {len(result['response']['patients'])}")
                if 'debug_info' in result['response']:
                    debug_info = result['response']['debug_info']
                    print(f"   📊 API Key Present: {debug_info.get('openai_api_key_present', False)}")
                    print(f"   📊 Valid Format: {debug_info.get('openai_api_key_valid_format', False)}")
        else:
            print(f"   ❌ Status: {result['status_code']} - FAILED")
            if result['error']:
                print(f"   💥 Error: {result['error']}")
            if result['response']:
                print(f"   📄 Response: {str(result['response'])[:100]}...")
    
    # Summary
    print("\n" + "=" * 60)
    print("📋 Test Results Summary:")
    
    passed = sum(1 for r in results if r['success'])
    total = len(results)
    
    for result in results:
        status = "✅ PASS" if result['success'] else "❌ FAIL"
        print(f"   {result['description']}: {status}")
    
    print(f"\n🎯 Overall: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Your Render deployment is working perfectly!")
    elif passed >= total - 1:
        print("⚠️ Almost all tests passed. Check any failed tests above.")
    else:
        print("🚨 Several tests failed. Check the errors above.")
    
    # Specific recommendations
    print("\n💡 Recommendations:")
    
    # Check ObjectId fix
    patients_test = next((r for r in results if 'Patients list' in r['description']), None)
    if patients_test and patients_test['success']:
        print("   ✅ ObjectId fix is working - patients endpoint returns proper JSON")
    else:
        print("   ❌ ObjectId fix may need attention - patients endpoint failed")
    
    # Check OpenAI
    openai_config_test = next((r for r in results if 'OpenAI configuration' in r['description']), None)
    if openai_config_test and openai_config_test['success']:
        if openai_config_test['response'] and 'debug_info' in openai_config_test['response']:
            debug_info = openai_config_test['response']['debug_info']
            if debug_info.get('openai_api_key_present', False):
                print("   ✅ OpenAI API key is configured")
            else:
                print("   ❌ OpenAI API key is missing - check Render environment variables")
    
    # Check root endpoint
    root_test = next((r for r in results if 'Root endpoint' in r['description']), None)
    if root_test and root_test['success']:
        print("   ✅ Root endpoint is working - visitors will see API info")
    else:
        print("   ❌ Root endpoint needs to be added to Flask app")
    
    print("\n🌐 Your API URLs:")
    print(f"   Root: {base_url}/")
    print(f"   Health: {base_url}/health")
    print(f"   Patients: {base_url}/patients")
    print(f"   OpenAI Debug: {base_url}/debug/openai-config")

if __name__ == "__main__":
    main()
