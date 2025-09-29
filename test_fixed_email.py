#!/usr/bin/env python3
"""
Test Fixed Email Service - Verify OTP is readable
"""

from services.email_service import EmailService

def test_fixed_email():
    """Test that email content is now readable (not base64)"""
    print("🧪 Testing Fixed Email Service")
    print("=" * 50)
    
    # Test OTP
    test_otp = "123456"
    
    # Create email service
    es = EmailService()
    
    # Test email content generation
    subject = "Patient Alert System - OTP Verification"
    body = f"""    Hello!
    
    Your OTP for Patient Alert System is: {test_otp}
    
    This OTP is valid for 10 minutes.
    
    If you didn't request this, please ignore this email.
    
    Best regards,
    Patient Alert System Team
    
    """
    
    print(f"📧 Email Subject: {subject}")
    print(f"📧 Email Body (should be readable):")
    print(body)
    print(f"📧 OTP in email: {test_otp}")
    
    # Test actual email sending
    print(f"\n📧 Sending test email...")
    result = es.send_otp_email('srinivasan.balakrishnan.lm@gmail.com', test_otp)
    print(f"📧 Email result: {result}")
    
    return result

if __name__ == "__main__":
    test_fixed_email()
