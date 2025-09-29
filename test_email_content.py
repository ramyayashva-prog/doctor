#!/usr/bin/env python3
"""
Test Email Content and OTP Delivery
"""

from services.email_service import EmailService
import base64

def test_email_content():
    """Test what the email content looks like"""
    print("🧪 Testing Email Content")
    print("=" * 50)
    
    # Test OTP
    test_otp = "123456"
    
    # Create email service
    es = EmailService()
    
    # Generate email content
    subject = "Patient Alert System - OTP Verification"
    body = f"""    Hello!
    
    Your OTP for Patient Alert System is: {test_otp}
    
    This OTP is valid for 10 minutes.
    
    If you didn't request this, please ignore this email.
    
    Best regards,
    Patient Alert System Team
    
    """
    
    print(f"📧 Email Subject: {subject}")
    print(f"📧 Email Body:")
    print(body)
    print(f"📧 OTP in email: {test_otp}")
    
    # Test base64 encoding (what's actually sent)
    body_bytes = body.encode('utf-8')
    body_b64 = base64.b64encode(body_bytes).decode('utf-8')
    
    print(f"\n📧 Base64 Encoded Body:")
    print(body_b64)
    
    # Decode to verify
    decoded = base64.b64decode(body_b64).decode('utf-8')
    print(f"\n📧 Decoded Body:")
    print(decoded)
    
    # Test actual email sending
    print(f"\n📧 Sending test email...")
    result = es.send_otp_email('srinivasan.balakrishnan.lm@gmail.com', test_otp)
    print(f"📧 Email result: {result}")
    
    return result

if __name__ == "__main__":
    test_email_content()
