"""
Email Service - Handles all email operations
"""

import smtplib
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import base64
from typing import Dict, Any, Optional

class EmailService:
    """Email service for sending emails"""
    
    def __init__(self):
        self.sender_email = os.environ.get('SENDER_EMAIL', 'ramya.sureshkumar.lm@gmail.com')
        self.sender_password = os.environ.get('SENDER_PASSWORD', 'djqs dktf gqor gnqg')
        self.smtp_server = 'smtp.gmail.com'
        self.smtp_port = 587
    
    def send_email(self, to_email: str, subject: str, body: str, is_html: bool = False) -> Dict[str, Any]:
        """Send email"""
        try:
            # Check if email configuration is available
            if not self.sender_email or not self.sender_password:
                print("❌ Email configuration not found")
                return {
                    'success': False,
                    'error': 'Email configuration not found'
                }
            
            # Create message
            msg = MIMEMultipart('mixed')
            msg['From'] = self.sender_email
            msg['To'] = to_email
            msg['Subject'] = subject
            msg['Reply-To'] = self.sender_email
            msg['X-Mailer'] = 'Patient Alert System'
            
            # Add body
            if is_html:
                msg.attach(MIMEText(body, 'html'))
            else:
                # Send plain text without base64 encoding
                msg.attach(MIMEText(body, 'plain', 'utf-8'))
            
            # Connect to server and send email
            print(f"📧 Attempting to send email to: {to_email}")
            print(f"📧 EMAIL DEBUG INFO:")
            print(f"   To: {to_email}")
            print(f"   From: {self.sender_email}")
            print(f"   Subject: {subject}")
            print(f"   Body length: {len(body)} characters")
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                print("📧 Connecting to Gmail SMTP...")
                server.starttls()
                print("📧 Starting TLS...")
                
                print("📧 Logging in...")
                server.login(self.sender_email, self.sender_password)
                
                print("📧 Sending email...")
                server.send_message(msg)
                
                print("✅ Email sent successfully")
                return {
                    'success': True,
                    'message': 'Email sent successfully'
                }
                
        except smtplib.SMTPAuthenticationError as e:
            print(f"❌ SMTP Authentication Error: {e}")
            return {
                'success': False,
                'error': 'SMTP authentication failed. Please check email credentials.'
            }
        except smtplib.SMTPRecipientsRefused as e:
            print(f"❌ SMTP Recipients Refused: {e}")
            return {
                'success': False,
                'error': 'Recipient email address is invalid or refused.'
            }
        except smtplib.SMTPServerDisconnected as e:
            print(f"❌ SMTP Server Disconnected: {e}")
            return {
                'success': False,
                'error': 'SMTP server disconnected unexpectedly.'
            }
        except Exception as e:
            print(f"❌ Email sending error: {e}")
            return {
                'success': False,
                'error': f'Failed to send email: {str(e)}'
            }
    
    def send_otp_email(self, email: str, otp: str) -> Dict[str, Any]:
        """Send OTP email"""
        try:
            subject = "Patient Alert System - OTP Verification"
            body = f"""    Hello!
    
    Your OTP for Patient Alert System is: {otp}
    
    This OTP is valid for 10 minutes.
    
    If you didn't request this, please ignore this email.
    
    Best regards,
    Patient Alert System Team
    
    """
            
            result = self.send_email(email, subject, body)
            
            if result['success']:
                print(f"✅ OTP email sent to: {email}")
                print(f"📧 Check your email in 1-2 minutes")
                print("✅ Primary email method successful")
            else:
                print(f"❌ Failed to send OTP email: {result['error']}")
                print(f"🔐 OTP for manual verification: {otp}")
                print("📧 Alternative: Check your email manually")
            
            return result
            
        except Exception as e:
            print(f"❌ OTP email error: {e}")
            return {
                'success': False,
                'error': f'Failed to send OTP email: {str(e)}'
            }
    
    def send_welcome_email(self, email: str, name: str, user_type: str) -> Dict[str, Any]:
        """Send welcome email"""
        try:
            subject = f"Welcome to Patient Alert System - {user_type.title()}"
            body = f"""    Hello {name}!
    
    Welcome to Patient Alert System!
    
    Your {user_type} account has been created successfully.
    
    You can now access all the features of our platform.
    
    Best regards,
    Patient Alert System Team
    
    """
            
            return self.send_email(email, subject, body)
            
        except Exception as e:
            print(f"❌ Welcome email error: {e}")
            return {
                'success': False,
                'error': f'Failed to send welcome email: {str(e)}'
            }
    
    def is_configured(self) -> bool:
        """Check if email service is configured"""
        return bool(self.sender_email and self.sender_password)
