"""
JWT Service - Handles JWT token operations
"""

import jwt
import rsa
import os
import time
import secrets
import string
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

class JWTService:
    """JWT service for token operations"""
    
    def __init__(self):
        self.private_key = None
        self.public_key = None
        self.algorithm = 'RS256'
        self._load_or_generate_keys()
    
    def _load_or_generate_keys(self):
        """Load existing RSA keys or generate new ones"""
        try:
            # Try to load existing keys
            if os.path.exists('jwt_private_key.pem') and os.path.exists('jwt_public_key.pem'):
                with open('jwt_private_key.pem', 'rb') as f:
                    self.private_key = rsa.PrivateKey.load_pkcs1(f.read())
                with open('jwt_public_key.pem', 'rb') as f:
                    self.public_key = rsa.PublicKey.load_pkcs1(f.read())
                print("🔑 Loading existing RSA keys from files...")
                print("✅ RSA keys loaded from files")
            else:
                # Generate new keys
                print("🔑 Generating new RSA keys...")
                self.public_key, self.private_key = rsa.newkeys(2048)
                
                # Save keys to files
                with open('jwt_private_key.pem', 'wb') as f:
                    f.write(self.private_key.save_pkcs1())
                with open('jwt_public_key.pem', 'wb') as f:
                    f.write(self.public_key.save_pkcs1())
                print("✅ RSA keys generated and saved to files")
                
        except Exception as e:
            print(f"❌ Error loading/generating RSA keys: {e}")
            # Generate new keys as fallback
            self.public_key, self.private_key = rsa.newkeys(2048)
    
    def generate_otp_jwt(self, email: str, purpose: str, signup_data: Dict[str, Any]) -> tuple[str, str]:
        """Generate JWT token with OTP"""
        try:
            # Generate OTP
            otp = self._generate_otp()
            
            # Create JWT payload
            current_time = int(time.time())
            payload = {
                'otp': otp,
                'email': email,
                'purpose': purpose,
                'attempts': 0,
                'max_attempts': 3,
                'jti': self._generate_jti(),
                'iat': current_time,
                'exp': current_time + 1800,  # 30 minutes
                'type': 'otp_token',
                'signup_data': signup_data
            }
            
            # Convert RSA key to PEM format
            private_key_pem = self.private_key.save_pkcs1().decode('utf-8')
            
            # Generate JWT token
            jwt_token = jwt.encode(payload, private_key_pem, algorithm=self.algorithm)
            
            print(f"🔐 OTP JWT created for {email}: {otp}")
            print(f"🔐 Generated new OTP: {otp} for email: {email}")
            
            return otp, jwt_token
            
        except Exception as e:
            print(f"❌ Error generating OTP JWT: {e}")
            raise
    
    def verify_otp_jwt(self, jwt_token: str, email: str, otp: str) -> Dict[str, Any]:
        """Verify OTP JWT token"""
        try:
            # Convert RSA key to PEM format
            public_key_pem = self.public_key.save_pkcs1().decode('utf-8')
            
            # Decode JWT token
            payload = jwt.decode(jwt_token, public_key_pem, algorithms=[self.algorithm])
            
            print(f"🔍 JWT Verification Debug:")
            print(f"  JWT Token: {jwt_token[:50]}...")
            print(f"  Public Key: {public_key_pem[:50]}...")
            print(f"  Decoded payload: {payload}")
            
            # Check token type
            if payload.get('type') != 'otp_token':
                return {
                    'success': False,
                    'error': 'Invalid token type'
                }
            
            # Check email match
            if payload.get('email') != email:
                return {
                    'success': False,
                    'error': 'Email mismatch'
                }
            
            # Check OTP match
            if payload.get('otp') != otp:
                return {
                    'success': False,
                    'error': 'Invalid OTP'
                }
            
            # Check expiration
            current_time = int(time.time())
            if payload.get('exp', 0) < current_time:
                return {
                    'success': False,
                    'error': 'Token expired'
                }
            
            # Check attempts
            attempts = payload.get('attempts', 0)
            max_attempts = payload.get('max_attempts', 3)
            if attempts >= max_attempts:
                return {
                    'success': False,
                    'error': 'Maximum attempts exceeded'
                }
            
            print(f"🔍 JWT Verification Time Debug:")
            print(f"  Current timestamp: {current_time}")
            print(f"  JWT exp timestamp: {payload.get('exp')}")
            print(f"  Time difference: {payload.get('exp') - current_time} seconds")
            
            print(f"🔍 JWT Verification Result: {{'success': True, 'data': {payload}, 'message': 'OTP verified successfully'}}")
            
            return {
                'success': True,
                'data': payload,
                'message': 'OTP verified successfully'
            }
            
        except jwt.ExpiredSignatureError:
            return {
                'success': False,
                'error': 'Token expired'
            }
        except jwt.InvalidTokenError as e:
            return {
                'success': False,
                'error': f'Invalid token: {str(e)}'
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'JWT verification error: {str(e)}'
            }
    
    def create_access_token(self, user_id: str, email: str, username: str, role: str, user_type: str, status: str) -> str:
        """Create access token"""
        try:
            current_time = int(time.time())
            payload = {
                'user_id': user_id,
                'email': email,
                'username': username,
                'role': role,
                'user_type': user_type,
                'status': status,
                'jti': self._generate_jti(),
                'iat': current_time,
                'exp': current_time + 900,  # 15 minutes
                'type': 'access_token'
            }
            
            # Convert RSA key to PEM format
            private_key_pem = self.private_key.save_pkcs1().decode('utf-8')
            
            # Generate JWT token
            access_token = jwt.encode(payload, private_key_pem, algorithm=self.algorithm)
            
            print(f"🔑 Access token created for {email}")
            return access_token
            
        except Exception as e:
            print(f"❌ Error creating access token: {e}")
            raise
    
    def create_refresh_token(self, user_id: str, user_type: str) -> str:
        """Create refresh token"""
        try:
            current_time = int(time.time())
            payload = {
                'user_id': user_id,
                'user_type': user_type,
                'jti': self._generate_jti(),
                'iat': current_time,
                'exp': current_time + 604800,  # 7 days
                'type': 'refresh_token'
            }
            
            # Convert RSA key to PEM format
            private_key_pem = self.private_key.save_pkcs1().decode('utf-8')
            
            # Generate JWT token
            refresh_token = jwt.encode(payload, private_key_pem, algorithm=self.algorithm)
            
            print(f"🔄 Refresh token created for {user_id}")
            return refresh_token
            
        except Exception as e:
            print(f"❌ Error creating refresh token: {e}")
            raise
    
    def verify_access_token(self, token: str) -> Dict[str, Any]:
        """Verify access token"""
        try:
            # Convert RSA key to PEM format
            public_key_pem = self.public_key.save_pkcs1().decode('utf-8')
            
            # Decode JWT token
            payload = jwt.decode(token, public_key_pem, algorithms=[self.algorithm])
            
            # Check token type
            if payload.get('type') != 'access_token':
                return {
                    'success': False,
                    'error': 'Invalid token type'
                }
            
            return {
                'success': True,
                'data': payload
            }
            
        except jwt.ExpiredSignatureError:
            return {
                'success': False,
                'error': 'Token expired'
            }
        except jwt.InvalidTokenError as e:
            return {
                'success': False,
                'error': f'Invalid token: {str(e)}'
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'Token verification error: {str(e)}'
            }
    
    def _generate_otp(self, length: int = 6) -> str:
        """Generate random OTP"""
        return ''.join(secrets.choice(string.digits) for _ in range(length))
    
    def generate_token(self, token_data: Dict[str, Any]) -> str:
        """Generate JWT token from token data"""
        try:
            current_time = int(time.time())
            payload = {
                'user_id': token_data.get('user_id', ''),
                'email': token_data.get('email', ''),
                'username': token_data.get('username', ''),
                'role': token_data.get('role', ''),
                'jti': self._generate_jti(),
                'iat': current_time,
                'exp': current_time + 3600,  # 1 hour
                'type': 'access_token'
            }
            
            # Convert RSA key to PEM format
            private_key_pem = self.private_key.save_pkcs1().decode('utf-8')
            
            # Generate JWT token
            jwt_token = jwt.encode(payload, private_key_pem, algorithm=self.algorithm)
            
            print(f"🔑 JWT token generated for {token_data.get('email', 'unknown')}")
            return jwt_token
            
        except Exception as e:
            print(f"❌ Error generating JWT token: {e}")
            raise
    
    def _generate_jti(self) -> str:
        """Generate JWT ID"""
        return secrets.token_urlsafe(32)
