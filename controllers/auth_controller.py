"""
Auth Controller - Handles authentication operations
"""

from flask import request, jsonify
from typing import Dict, Any

class AuthController:
    """Authentication controller"""
    
    def __init__(self, doctor_model, patient_model, otp_model, jwt_service, email_service, validators):
        self.doctor_model = doctor_model
        self.patient_model = patient_model
        self.otp_model = otp_model
        self.jwt_service = jwt_service
        self.email_service = email_service
        self.validators = validators
    
    def doctor_signup(self, request) -> tuple:
        """Doctor signup endpoint"""
        try:
            data = request.get_json()
            
            # Extract doctor signup data
            username = data.get('username', '').strip()
            email = data.get('email', '').strip()
            mobile = data.get('mobile', '').strip()
            password = data.get('password', '')
            role = data.get('role', 'doctor')
            
            # Validate required fields
            if not all([username, email, mobile, password]):
                return jsonify({'error': 'Missing required fields'}), 400
            
            # Validate email and mobile
            if not self.validators.validate_email(email):
                return jsonify({"error": "Invalid email format"}), 400
            
            if not self.validators.validate_mobile(mobile):
                return jsonify({"error": "Invalid mobile number"}), 400
            
            # Check if email already exists
            if self.doctor_model.check_email_exists(email):
                return jsonify({'error': 'Email already exists'}), 400
            
            # Check if username already exists
            if self.doctor_model.check_username_exists(username):
                return jsonify({'error': 'Username already exists'}), 400
            
            # Check if mobile already exists
            if self.doctor_model.check_mobile_exists(mobile):
                return jsonify({'error': 'Mobile number already exists'}), 400
            
            # Prepare signup data for JWT
            signup_data = {
                'username': username,
                'email': email,
                'mobile': mobile,
                'password': password,
                'role': role,
            }
            
            # Store signup data temporarily for resend OTP functionality
            temp_result = self.otp_model.store_temp_signup_data(email, signup_data)
            if not temp_result['success']:
                return jsonify({'error': temp_result['error']}), 500
            
            print(f"💾 Stored temporary signup data for email: {email}")
            print(f"✅ Doctor signup data stored for email: {email}")
            print(f"📝 Next step: Call /doctor-send-otp to send OTP")
            
            return jsonify({
                'success': True,
                'message': 'Doctor signup data collected successfully. Please call /doctor-send-otp to send OTP.',
                'email': email,
                'username': username,
                'mobile': mobile,
                'role': role
            }), 200
                
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def patient_signup(self, request) -> tuple:
        """Patient signup endpoint"""
        try:
            data = request.get_json()
            
            # Extract patient signup data
            username = data.get('username', '').strip()
            email = data.get('email', '').strip()
            mobile = data.get('mobile', '').strip()
            password = data.get('password', '')
            role = data.get('role', 'patient')
            
            # Validate required fields
            if not all([username, email, mobile, password]):
                return jsonify({'error': 'Missing required fields'}), 400
            
            # Validate email and mobile
            if not self.validators.validate_email(email):
                return jsonify({"error": "Invalid email format"}), 400
            
            if not self.validators.validate_mobile(mobile):
                return jsonify({"error": "Invalid mobile number"}), 400
            
            # Check if email already exists
            if self.patient_model.check_email_exists(email):
                return jsonify({'error': 'Email already exists'}), 400
            
            # Check if username already exists
            if self.patient_model.check_username_exists(username):
                return jsonify({'error': 'Username already exists'}), 400
            
            # Check if mobile already exists
            if self.patient_model.check_mobile_exists(mobile):
                return jsonify({'error': 'Mobile number already exists'}), 400
            
            # Create patient
            result = self.patient_model.create_patient({
                'username': username,
                'email': email,
                'mobile': mobile,
                'password': password,
                'role': role
            })
            
            if result['success']:
                return jsonify({
                    'success': True,
                    'message': 'Patient created successfully',
                    'patient_id': result['patient_id']
                }), 200
            else:
                return jsonify({'error': result['error']}), 500
                
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def login(self, request) -> tuple:
        """Login endpoint for both doctors and patients"""
        try:
            data = request.get_json()
            
            # Extract login data
            email = data.get('email', '').strip()
            password = data.get('password', '')
            role = data.get('role', 'patient')  # Default to patient
            
            # Validate required fields
            if not all([email, password]):
                return jsonify({'error': 'Email and password are required'}), 400
            
            # Validate email format only if it looks like an email
            if '@' in email and not self.validators.validate_email(email):
                return jsonify({"error": "Invalid email format"}), 400
            
            # Try to authenticate based on role
            if role == 'doctor':
                # Try to find doctor by email or doctor_id
                doctor = None
                if '@' in email:
                    # Looks like an email
                    doctor = self.doctor_model.get_doctor_by_email(email)
                else:
                    # Try as doctor_id
                    doctor = self.doctor_model.get_doctor_by_id(email)
                
                if not doctor:
                    return jsonify({'error': 'Invalid credentials'}), 401
                
                # Verify password using the identifier (email or doctor_id)
                if not self.doctor_model.verify_password(email, password):
                    return jsonify({'error': 'Invalid credentials'}), 401
                
                # Generate JWT token
                token_data = {
                    'user_id': doctor.get('doctor_id', ''),
                    'email': doctor.get('email', ''),
                    'username': doctor.get('username', ''),
                    'role': 'doctor'
                }
                token = self.jwt_service.generate_token(token_data)
                
                return jsonify({
                    'success': True,
                    'message': 'Login successful',
                    'token': token,
                    'doctor_id': doctor.get('doctor_id', ''),
                    'email': doctor.get('email', ''),
                    'username': doctor.get('username', ''),
                    'user': {
                        'id': doctor.get('doctor_id', ''),
                        'email': doctor.get('email', ''),
                        'username': doctor.get('username', ''),
                        'role': 'doctor'
                    }
                }), 200
                
            else:  # patient role
                # Check if patient exists and verify password
                patient = self.patient_model.get_patient_by_email(email)
                if not patient:
                    return jsonify({'error': 'Invalid credentials'}), 401
                
                # Verify password (you'll need to implement password verification)
                if not self.patient_model.verify_password(patient['_id'], password):
                    return jsonify({'error': 'Invalid credentials'}), 401
                
                # Generate JWT token
                token_data = {
                    'user_id': str(patient['_id']),
                    'email': patient['email'],
                    'username': patient['username'],
                    'role': 'patient'
                }
                token = self.jwt_service.generate_token(token_data)
                
                return jsonify({
                    'success': True,
                    'message': 'Login successful',
                    'token': token,
                    'user': {
                        'id': str(patient['_id']),
                        'email': patient['email'],
                        'username': patient['username'],
                        'role': 'patient'
                    }
                }), 200
                
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def doctor_login(self, request) -> tuple:
        """Doctor-only login endpoint"""
        try:
            data = request.get_json()
            
            # Extract login data
            email = data.get('email', '').strip()
            password = data.get('password', '')
            
            # Validate required fields
            if not all([email, password]):
                return jsonify({'error': 'Email and password are required'}), 400
            
            # Validate email format only if it looks like an email
            if '@' in email and not self.validators.validate_email(email):
                return jsonify({"error": "Invalid email format"}), 400
            
            # Try to find doctor by email or doctor_id
            doctor = None
            if '@' in email:
                # Looks like an email
                doctor = self.doctor_model.get_doctor_by_email(email)
            else:
                # Try as doctor_id
                doctor = self.doctor_model.get_doctor_by_id(email)
            
            if not doctor:
                print(f"❌ Doctor not found for email/doctor_id: {email}")
                return jsonify({'error': 'Invalid credentials'}), 401
            
            print(f"✅ Doctor found: {doctor.get('username', 'Unknown')} ({doctor.get('doctor_id', 'No ID')})")
            
            # Verify password using the identifier (email or doctor_id)
            password_valid = self.doctor_model.verify_password(email, password)
            if not password_valid:
                print(f"❌ Password verification failed for: {email}")
                return jsonify({'error': 'Invalid credentials'}), 401
            
            print(f"✅ Password verified for: {email}")
            
            # Generate JWT token
            token_data = {
                'user_id': doctor.get('doctor_id', ''),
                'email': doctor.get('email', ''),
                'username': doctor.get('username', ''),
                'role': 'doctor'
            }
            token = self.jwt_service.generate_token(token_data)
            
            return jsonify({
                'success': True,
                'message': 'Login successful',
                'token': token,
                'doctor_id': doctor.get('doctor_id', ''),
                'email': doctor.get('email', ''),
                'username': doctor.get('username', ''),
                'user': {
                    'id': doctor.get('doctor_id', ''),
                    'email': doctor.get('email', ''),
                    'username': doctor.get('username', ''),
                    'role': 'doctor'
                }
            }), 200
                
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500