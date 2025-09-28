#!/usr/bin/env python3
"""
AI Summary Endpoint Debug Script
Tests the AI summary functionality on Render deployment
"""

import requests
import json
from datetime import datetime

def test_ai_summary_debug():
    """Debug AI summary endpoint issues"""
    base_url = "https://doctor-9don.onrender.com"
    
    print("🧪 AI Summary Endpoint Debug Test")
    print(f"🌐 Base URL: {base_url}")
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Test 1: OpenAI Configuration
    print("1. 🔍 Testing OpenAI Configuration...")
    try:
        response = requests.get(f"{base_url}/debug/openai-config", timeout=10)
        if response.status_code == 200:
            data = response.json()
            debug_info = data.get('debug_info', {})
            
            print(f"   ✅ Status: {response.status_code}")
            print(f"   📊 API Key Present: {debug_info.get('openai_api_key_present', False)}")
            print(f"   📊 Valid Format: {debug_info.get('openai_api_key_valid_format', False)}")
            
            if debug_info.get('openai_api_key_present'):
                key_format = debug_info.get('openai_api_key_format', 'Unknown')
                print(f"   📊 Key Format: {key_format}")
            
            config_ok = debug_info.get('openai_api_key_present', False) and debug_info.get('openai_api_key_valid_format', False)
            if not config_ok:
                print("   ❌ OpenAI configuration issue detected")
                return False
            else:
                print("   ✅ OpenAI configuration looks good")
        else:
            print(f"   ❌ Failed: {response.status_code}")
            print(f"   📄 Response: {response.text[:200]}")
            return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False
    
    # Test 2: OpenAI API Connection
    print("\n2. 🔍 Testing OpenAI API Connection...")
    try:
        response = requests.get(f"{base_url}/debug/test-openai", timeout=30)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Status: {response.status_code}")
            print(f"   📊 Success: {data.get('success', False)}")
            print(f"   📊 Response: {data.get('openai_response', 'N/A')}")
            print(f"   📊 Model: {data.get('model_used', 'N/A')}")
            print(f"   📊 Tokens: {data.get('tokens_used', 'N/A')}")
            
            if data.get('success'):
                print("   ✅ OpenAI API connection working")
                api_ok = True
            else:
                print("   ❌ OpenAI API test failed")
                api_ok = False
        else:
            print(f"   ❌ Failed: {response.status_code}")
            print(f"   📄 Response: {response.text}")
            api_ok = False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        api_ok = False
    
    # Test 3: Authentication
    print("\n3. 🔍 Testing Authentication...")
    try:
        login_data = {
            "email": "testdoctor@example.com",
            "password": "testpass123"
        }
        
        response = requests.post(
            f"{base_url}/doctor-login",
            json=login_data,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('token')
            print(f"   ✅ Login successful")
            print(f"   📊 Doctor ID: {data.get('doctor_id', 'N/A')}")
            print(f"   📊 Token: {token[:20] if token else 'N/A'}...")
            auth_ok = bool(token)
        else:
            print(f"   ❌ Login failed: {response.status_code}")
            print(f"   📄 Response: {response.text}")
            auth_ok = False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        auth_ok = False
    
    # Test 4: Patient Data (if auth works)
    if auth_ok:
        print("\n4. 🔍 Testing Patient Data...")
        try:
            headers = {"Authorization": f"Bearer {token}"}
            
            # Test getting patient list
            response = requests.get(
                f"{base_url}/patients?page=1&limit=1",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                patients = data.get('patients', [])
                print(f"   ✅ Patient data accessible")
                print(f"   📊 Patients found: {len(patients)}")
                
                if patients:
                    patient_id = patients[0].get('patient_id')
                    print(f"   📊 Sample Patient ID: {patient_id}")
                    patient_ok = True
                else:
                    print("   ⚠️ No patients found - cannot test AI summary")
                    patient_ok = False
            else:
                print(f"   ❌ Patient data failed: {response.status_code}")
                patient_ok = False
        except Exception as e:
            print(f"   ❌ Error: {e}")
            patient_ok = False
    else:
        patient_ok = False
    
    # Test 5: AI Summary (if all prerequisites work)
    if auth_ok and api_ok and patient_ok and 'patient_id' in locals():
        print(f"\n5. 🔍 Testing AI Summary for Patient {patient_id}...")
        try:
            headers = {"Authorization": f"Bearer {token}"}
            
            response = requests.get(
                f"{base_url}/doctor/patient/{patient_id}/ai-summary",
                headers=headers,
                timeout=60  # Longer timeout for AI processing
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"   ✅ AI Summary request successful")
                print(f"   📊 Success: {data.get('success', False)}")
                
                if data.get('success'):
                    ai_summary = data.get('ai_summary', '')
                    print(f"   📊 Summary Length: {len(ai_summary)} characters")
                    print(f"   📊 Patient Name: {data.get('patient_name', 'N/A')}")
                    print(f"   📊 Summary Stats: {data.get('summary_stats', {})}")
                    print("   ✅ AI Summary generation working!")
                    summary_ok = True
                else:
                    print(f"   ❌ AI Summary failed: {data.get('message', 'Unknown error')}")
                    summary_ok = False
            else:
                print(f"   ❌ AI Summary request failed: {response.status_code}")
                print(f"   📄 Response: {response.text}")
                summary_ok = False
        except Exception as e:
            print(f"   ❌ Error: {e}")
            summary_ok = False
    else:
        summary_ok = False
        print(f"\n5. ⏭️ Skipping AI Summary test - prerequisites not met")
    
    # Summary
    print("\n" + "=" * 60)
    print("📋 Debug Results Summary:")
    print(f"   OpenAI Configuration: {'✅ PASS' if config_ok else '❌ FAIL'}")
    print(f"   OpenAI API Connection: {'✅ PASS' if api_ok else '❌ FAIL'}")
    print(f"   Authentication: {'✅ PASS' if auth_ok else '❌ FAIL'}")
    print(f"   Patient Data: {'✅ PASS' if patient_ok else '❌ FAIL'}")
    print(f"   AI Summary: {'✅ PASS' if summary_ok else '❌ FAIL'}")
    
    # Recommendations
    print("\n💡 Recommendations:")
    
    if not config_ok:
        print("   🔧 Fix OpenAI API key configuration in Render Dashboard")
    elif not api_ok:
        print("   🔧 Check OpenAI API key validity and billing")
    elif not auth_ok:
        print("   🔧 Verify doctor login credentials")
    elif not patient_ok:
        print("   🔧 Check patient data in database")
    elif not summary_ok:
        print("   🔧 Check AI summary endpoint implementation")
    else:
        print("   🎉 All tests passed! AI summary should be working.")
    
    return summary_ok

if __name__ == "__main__":
    test_ai_summary_debug()
