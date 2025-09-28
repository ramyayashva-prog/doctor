#!/usr/bin/env python3
"""
Test OpenAI library version and compatibility
"""

def test_openai_version():
    """Test OpenAI library version and basic functionality"""
    print("🧪 Testing OpenAI Library Version and Compatibility")
    print("=" * 60)
    
    try:
        import openai
        print(f"✅ OpenAI library imported successfully")
        print(f"📊 Version: {openai.__version__}")
        
        # Test client initialization
        try:
            from openai import OpenAI
            print("✅ OpenAI class imported successfully")
            
            # Test minimal initialization
            try:
                client = OpenAI(api_key="test-key")
                print("✅ Minimal client initialization successful")
            except Exception as e:
                print(f"❌ Minimal client initialization failed: {e}")
                
                # Test with explicit parameters
                try:
                    client = OpenAI(api_key="test-key", timeout=30.0)
                    print("✅ Explicit client initialization successful")
                except Exception as e2:
                    print(f"❌ Explicit client initialization failed: {e2}")
                    
                    # Test legacy method
                    try:
                        openai.api_key = "test-key"
                        print("✅ Legacy API key setting successful")
                    except Exception as e3:
                        print(f"❌ Legacy method failed: {e3}")
                        
        except Exception as e:
            print(f"❌ OpenAI class import failed: {e}")
            
    except ImportError as e:
        print(f"❌ OpenAI library not installed: {e}")
        print("💡 Install with: pip install openai")
        return False
    
    print("\n🎯 Recommendations:")
    print("- If minimal initialization works: Use OpenAI(api_key=api_key)")
    print("- If explicit initialization works: Use OpenAI(api_key=api_key, timeout=30.0)")
    print("- If legacy method works: Use openai.api_key = api_key")
    
    return True

if __name__ == "__main__":
    test_openai_version()
