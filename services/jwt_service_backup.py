"""
JWT Service - Handles JWT token operations with fallback to HMAC
"""

import jwt
import os
import time
import secrets
import string
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

class JWTService:
    """JWT service for token operations with RSA/HMAC fallback"""
    
    def __init__(self):
        self.algorithm = 'HS256'  # Use HMAC by default (more reliable)
        self.secret_key = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-this')
        
        # Try to use RSA if available, fallback to HMAC
        try:
            import rsa
            self.private_key = None
            self.public_key = None
            self.algorithm = 'RS256'
            self._load_or_generate_keys()
            print("🔑 Using RS256 algorithm with RSA keys")
        except ImportError:
            print("🔑 RSA not available, using HS256 algorithm with HMAC")
            self.algorithm = 'HS256'
    
    def _load_or_generate_keys(self):
        """Load existing RSA keys or generate new ones (only if RSA is available)"""
        if self.algorithm != 'RS256':
            return
            
        try:
            import rsa
            # Try to load existing keys
            if os.path.exists('jwt_private_key.pem') and os.path.exists('jwt_public_key.pem'):
                with open('jwt_private_key.pem', 'rb') as f:
                    self.private_key = rsa.PrivateKey.load_pkcs1(f.read())
                with open('jwt_public_key.pem', 'rb') as f:
                    self.public_key = rsa.PublicKey.load_pkcs1(f.read())
                print("🔑 Loading existing RSA keys from files...")
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
            print(f"❌ Error with RSA keys, falling back to HMAC: {e}")
            self.algorithm = 'HS256'
    
    def _encode_token(self, payload: dict) -> str:
        """Encode JWT token with current algorithm"""
        if self.algorithm == 'RS256':
            private_key_pem = self.private_key.save_pkcs1().decode('utf-8')
            return jwt.encode(payload, private_key_pem, algorithm=self.algorithm)
        else:
            return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
    
    def _decode_token(self, token: str) -> dict:
        """Decode JWT token with current algorithm"""
        if self.algorithm == 'RS256':
            public_key_pem = self.public_key.save_pkcs1().decode('utf-8')
            return jwt.decode(token, public_key_pem, algorithms=[self.algorithm])
        else:
            return jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
    
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
            
            # Generate JWT token
            jwt_token = self._encode_token(payload)
            
            print(f"🔐 OTP JWT created for {email}: {otp}")
            return otp, jwt_token
            
        except Exception as e:
            print(f"❌ Error generating OTP JWT: {e}")
            raise
    
    def verify_otp_jwt(self, jwt_token: str, email: str, otp: str) -> Dict[str, Any]:
        """Verify OTP JWT token"""
        try:
            # Decode JWT token
            payload = self._decode_token(jwt_token)
            
            # Check token type
            if payload.get('type') != 'otp_token':
                return {'success': False, 'error': 'Invalid token type'}
            
            # Check email match
            if payload.get('email') != email:
                return {'success': False, 'error': 'Email mismatch'}
            
            # Check OTP match
            if payload.get('otp') != otp:
                return {'success': False, 'error': 'Invalid OTP'}
            
            # Check expiration
            current_time = int(time.time())
            if payload.get('exp', 0) < current_time:
                return {'success': False, 'error': 'Token expired'}
            
            # Check attempts
            attempts = payload.get('attempts', 0)
            max_attempts = payload.get('max_attempts', 3)
            if attempts >= max_attempts:
                return {'success': False, 'error': 'Maximum attempts exceeded'}
            
            return {
                'success': True,
                'data': payload,
                'message': 'OTP verified successfully'
            }
            
        except jwt.ExpiredSignatureError:
            return {'success': False, 'error': 'Token expired'}
        except jwt.InvalidTokenError as e:
            return {'success': False, 'error': f'Invalid token: {str(e)}'}
        except Exception as e:
            return {'success': False, 'error': f'JWT verification error: {str(e)}'}
    
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
            
            # Generate JWT token
            access_token = self._encode_token(payload)
            
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
            
            # Generate JWT token
            refresh_token = self._encode_token(payload)
            
            print(f"🔄 Refresh token created for {user_id}")
            return refresh_token
            
        except Exception as e:
            print(f"❌ Error creating refresh token: {e}")
            raise
    
    def verify_access_token(self, token: str) -> Dict[str, Any]:
        """Verify access token"""
        try:
            # Decode JWT token
            payload = self._decode_token(token)
            
            # Check token type
            if payload.get('type') != 'access_token':
                return {'success': False, 'error': 'Invalid token type'}
            
            return {'success': True, 'data': payload}
            
        except jwt.ExpiredSignatureError:
            return {'success': False, 'error': 'Token expired'}
        except jwt.InvalidTokenError as e:
            return {'success': False, 'error': f'Invalid token: {str(e)}'}
        except Exception as e:
            return {'success': False, 'error': f'Token verification error: {str(e)}'}
    
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
            
            # Generate JWT token
            jwt_token = self._encode_token(payload)
            
            print(f"🔑 JWT token generated for {token_data.get('email', 'unknown')}")
            return jwt_token
            
        except Exception as e:
            print(f"❌ Error generating JWT token: {e}")
            raise
    
    def _generate_jti(self) -> str:
        """Generate JWT ID"""
        return secrets.token_urlsafe(32)
