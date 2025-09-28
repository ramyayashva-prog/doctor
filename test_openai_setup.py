#!/usr/bin/env python3
"""
OpenAI API Key Setup Test Script

This script helps you test if your OpenAI API key is properly configured
for both local development and Render deployment.
"""

import os
import requests
import json
from dotenv import load_dotenv

def test_openai_api_key():
    """Test OpenAI API key configuration"""
    print("🔑 Testing OpenAI API Key Configuration...")
    
    # Load environment variables
    load_dotenv()
    
    # Get API key from environment
    api_key = os.getenv('OPENAI_API_KEY')
    
    if not api_key:
        print("❌ OPENAI_API_KEY not found in environment variables")
        print("💡 Solutions:")
        print("   1. Local: Add OPENAI_API_KEY to your .env file")
        print("   2. Render: Set OPENAI_API_KEY in Render Dashboard > Environment")
        return False
    
    if not api_key.startswith('sk-'):
        print("❌ Invalid API key format (should start with 'sk-')")
        return False
    
    print(f"✅ API Key found: {api_key[:10]}...{api_key[-4:]}")
    
    # Test OpenAI API connection
    try:
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(
            'https://api.openai.com/v1/models',
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200:
            print("✅ OpenAI API connection successful")
            models = response.json()
            gpt_models = [m['id'] for m in models['data'] if 'gpt' in m['id']]
            print(f"✅ Available GPT models: {', '.join(gpt_models[:3])}...")
            return True
        else:
            print(f"❌ OpenAI API error: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")
        return False

def test_ai_summary_endpoint(base_url="http://localhost:5000"):
    """Test AI summary endpoint"""
    print(f"\n🤖 Testing AI Summary Endpoint at {base_url}...")
    
    # Test patient ID (you may need to change this)
    patient_id = "PAT1758712159E182A3"
    
    try:
        # First, test health endpoint
        health_response = requests.get(f"{base_url}/health", timeout=5)
        if health_response.status_code != 200:
            print(f"❌ Health check failed: {health_response.status_code}")
            return False
        
        print("✅ Server health check passed")
        
        # Test AI summary endpoint (without auth for now, just to check the error)
        ai_response = requests.get(
            f"{base_url}/doctor/patient/{patient_id}/ai-summary",
            timeout=10
        )
        
        if ai_response.status_code == 401:
            print("✅ AI summary endpoint is accessible (auth required)")
            print("💡 To test with authentication, use the Postman collection")
            return True
        elif ai_response.status_code == 500:
            response_data = ai_response.json()
            if "Failed to generate AI summary" in response_data.get('message', ''):
                print("❌ AI summary failed - likely missing OpenAI API key")
                print("💡 Check your OpenAI API key configuration")
                return False
            else:
                print(f"❌ Unexpected error: {response_data}")
                return False
        else:
            print(f"✅ AI summary endpoint responded with: {ai_response.status_code}")
            return True
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 OpenAI Setup Test Script")
    print("=" * 50)
    
    # Test local OpenAI API key
    openai_ok = test_openai_api_key()
    
    # Test local AI summary endpoint
    local_ok = test_ai_summary_endpoint("http://localhost:5000")
    
    print("\n" + "=" * 50)
    print("📋 Test Results Summary:")
    print(f"   OpenAI API Key: {'✅ OK' if openai_ok else '❌ FAILED'}")
    print(f"   Local AI Endpoint: {'✅ OK' if local_ok else '❌ FAILED'}")
    
    if not openai_ok:
        print("\n🔧 Setup Instructions:")
        print("1. Get OpenAI API key from: https://platform.openai.com/api-keys")
        print("2. Local: Add to .env file: OPENAI_API_KEY=sk-your-key-here")
        print("3. Render: Set in Dashboard > Environment > OPENAI_API_KEY")
        print("4. Restart server after adding the key")
    
    if openai_ok and not local_ok:
        print("\n💡 AI Summary endpoint may need authentication token")
        print("   Use the Postman collection to test with proper auth")
    
    print("\n🎯 Next Steps:")
    print("1. Configure OpenAI API key (if not done)")
    print("2. Test with Postman collection")
    print("3. Deploy to Render with environment variables")

if __name__ == "__main__":
    main()
