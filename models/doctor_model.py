"""
Doctor Model - Handles doctor-related database operations
"""

from datetime import datetime
import hashlib
import secrets
import string
from typing import Dict, Any, Optional

class DoctorModel:
    """Doctor data model and operations"""
    
    def __init__(self, database):
        self.db = database
        self._update_collection()
    
    def _update_collection(self):
        """Update collection reference"""
        if self.db and hasattr(self.db, 'doctors_collection') and self.db.doctors_collection is not None:
            self.collection = self.db.doctors_collection
        else:
            self.collection = None
    
    def create_doctor(self, doctor_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new doctor"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return {
                    'success': False,
                    'error': 'Database not connected'
                }
            
            # Generate unique doctor ID
            doctor_id = self._generate_doctor_id()
            
            # Hash password
            password_hash = self._hash_password(doctor_data['password'])
            
            # Prepare doctor document
            doctor_doc = {
                'doctor_id': doctor_id,
                'username': doctor_data['username'],
                'email': doctor_data['email'],
                'mobile': doctor_data['mobile'],
                'password_hash': password_hash,
                'role': 'doctor',
                'status': 'pending_profile',
                'email_verified': False,
                'verified_at': None,
                'created_at': datetime.utcnow(),
                'updated_at': datetime.utcnow(),
                'profile_completed_at': None,
                'first_name': '',
                'last_name': '',
                'specialization': '',
                'license_number': '',
                'experience_years': 0,
                'hospital_name': '',
                'address': '',
                'city': '',
                'state': '',
                'pincode': '',
                'consultation_fee': 0,
                'available_timings': {},
                'languages': [],
                'qualifications': []
            }
            
            # Insert doctor
            result = self.collection.insert_one(doctor_doc)
            
            if result.inserted_id:
                return {
                    'success': True,
                    'doctor_id': doctor_id,
                    'message': 'Doctor created successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create doctor'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Database error: {str(e)}'
            }
    
    def get_doctor_by_id(self, doctor_id: str) -> Optional[Dict[str, Any]]:
        """Get doctor by ID"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return None
            
            doctor = self.collection.find_one({'doctor_id': doctor_id})
            if doctor:
                # Remove sensitive data
                doctor.pop('password_hash', None)
                doctor.pop('_id', None)
                return doctor
            return None
        except Exception as e:
            print(f"❌ Error getting doctor: {e}")
            return None
    
    def get_doctor_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get doctor by email"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return None
            
            doctor = self.collection.find_one({'email': email})
            if doctor:
                # Remove sensitive data
                doctor.pop('password_hash', None)
                doctor.pop('_id', None)
                return doctor
            return None
        except Exception as e:
            print(f"❌ Error getting doctor by email: {e}")
            return None
    
    def get_doctor_by_id(self, doctor_id: str) -> Optional[Dict[str, Any]]:
        """Get doctor by doctor_id"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return None
            
            doctor = self.collection.find_one({'doctor_id': doctor_id})
            if doctor:
                # Remove sensitive data
                doctor.pop('password_hash', None)
                doctor.pop('_id', None)
                return doctor
            return None
        except Exception as e:
            print(f"❌ Error getting doctor by ID: {e}")
            return None
    
    def update_doctor_profile(self, doctor_id: str, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update doctor profile"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return {
                    'success': False,
                    'error': 'Database not connected'
                }
            
            # Prepare update data
            update_data = {
                'first_name': profile_data.get('first_name', ''),
                'last_name': profile_data.get('last_name', ''),
                'specialization': profile_data.get('specialization', ''),
                'license_number': profile_data.get('license_number', ''),
                'experience_years': profile_data.get('experience_years', 0),
                'hospital_name': profile_data.get('hospital_name', ''),
                'address': profile_data.get('address', ''),
                'city': profile_data.get('city', ''),
                'state': profile_data.get('state', ''),
                'pincode': profile_data.get('pincode', ''),
                'consultation_fee': profile_data.get('consultation_fee', 0),
                'profile_url': profile_data.get('profile_url', ''),
                'available_timings': profile_data.get('available_timings', {}),
                'languages': profile_data.get('languages', []),
                'qualifications': profile_data.get('qualifications', []),
                'updated_at': datetime.utcnow()
            }
            
            # Update doctor
            result = self.collection.update_one(
                {'doctor_id': doctor_id},
                {'$set': update_data}
            )
            
            if result.modified_count > 0:
                return {
                    'success': True,
                    'message': 'Profile updated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'No changes made or doctor not found'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Database error: {str(e)}'
            }
    
    def complete_doctor_profile(self, doctor_id: str, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        """Complete doctor profile"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return {
                    'success': False,
                    'error': 'Database not connected'
                }
            
            # Prepare update data
            update_data = {
                'first_name': profile_data.get('first_name', ''),
                'last_name': profile_data.get('last_name', ''),
                'specialization': profile_data.get('specialization', ''),
                'license_number': profile_data.get('license_number', ''),
                'experience_years': profile_data.get('experience_years', 0),
                'hospital_name': profile_data.get('hospital_name', ''),
                'address': profile_data.get('address', ''),
                'city': profile_data.get('city', ''),
                'state': profile_data.get('state', ''),
                'pincode': profile_data.get('pincode', ''),
                'consultation_fee': profile_data.get('consultation_fee', 0),
                'available_timings': profile_data.get('available_timings', {}),
                'languages': profile_data.get('languages', []),
                'qualifications': profile_data.get('qualifications', []),
                'status': 'active',
                'profile_completed_at': datetime.utcnow(),
                'updated_at': datetime.utcnow()
            }
            
            # Update doctor
            result = self.collection.update_one(
                {'doctor_id': doctor_id},
                {'$set': update_data}
            )
            
            if result.modified_count > 0:
                return {
                    'success': True,
                    'message': 'Profile completed successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'No changes made or doctor not found'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Database error: {str(e)}'
            }
    
    def verify_doctor_email(self, doctor_id: str) -> Dict[str, Any]:
        """Verify doctor email"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return {
                    'success': False,
                    'error': 'Database not connected'
                }
            
            result = self.collection.update_one(
                {'doctor_id': doctor_id},
                {
                    '$set': {
                        'email_verified': True,
                        'verified_at': datetime.utcnow(),
                        'updated_at': datetime.utcnow()
                    }
                }
            )
            
            if result.modified_count > 0:
                return {
                    'success': True,
                    'message': 'Email verified successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Doctor not found'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Database error: {str(e)}'
            }
    
    def check_email_exists(self, email: str) -> bool:
        """Check if email already exists"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return False
            
            doctor = self.collection.find_one({'email': email})
            return doctor is not None
        except Exception as e:
            print(f"❌ Error checking email: {e}")
            return False
    
    def check_username_exists(self, username: str) -> bool:
        """Check if username already exists"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return False
            
            doctor = self.collection.find_one({'username': username})
            return doctor is not None
        except Exception as e:
            print(f"❌ Error checking username: {e}")
            return False
    
    def check_mobile_exists(self, mobile: str) -> bool:
        """Check if mobile already exists"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return False
            
            doctor = self.collection.find_one({'mobile': mobile})
            return doctor is not None
        except Exception as e:
            print(f"❌ Error checking mobile: {e}")
            return False
    
    def _generate_doctor_id(self) -> str:
        """Generate unique doctor ID"""
        timestamp = str(int(datetime.utcnow().timestamp() * 1000))
        random_suffix = ''.join(secrets.choice(string.digits) for _ in range(4))
        return f"D{timestamp}{random_suffix}"
    
    def _hash_password(self, password: str) -> str:
        """Hash password using bcrypt"""
        import bcrypt
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')
    
    def verify_password(self, identifier: str, password: str) -> bool:
        """Verify password for a doctor using email or doctor_id"""
        try:
            # Try to find doctor by email first, then by doctor_id
            doctor = None
            
            # Check if identifier looks like an email
            if '@' in identifier:
                doctor = self.collection.find_one({'email': identifier})
            else:
                # Try as doctor_id
                doctor = self.collection.find_one({'doctor_id': identifier})
            
            if not doctor or 'password_hash' not in doctor:
                print(f"❌ Doctor not found or no password_hash for: {identifier}")
                return False
            
            import bcrypt
            # Get the stored password hash
            password_hash = doctor['password_hash']
            
            # Debug information
            print(f"🔍 Password verification debug:")
            print(f"   Identifier: {identifier}")
            print(f"   Password hash type: {type(password_hash)}")
            print(f"   Password hash length: {len(password_hash) if password_hash else 0}")
            print(f"   Input password: {password}")
            
            # Convert password_hash to bytes if it's a string
            if isinstance(password_hash, str):
                password_hash = password_hash.encode('utf-8')
            
            # Verify password
            is_valid = bcrypt.checkpw(password.encode('utf-8'), password_hash)
            print(f"   Password verification result: {is_valid}")
            
            return is_valid
            
        except Exception as e:
            print(f"❌ Error verifying password: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def reset_password(self, email: str, new_password: str) -> Dict[str, Any]:
        """Reset doctor password"""
        try:
            # Update collection reference
            self._update_collection()
            
            if self.collection is None:
                return {
                    'success': False,
                    'error': 'Database not connected'
                }
            
            # Hash the new password
            from werkzeug.security import generate_password_hash
            hashed_password = generate_password_hash(new_password)
            
            # Update password
            result = self.collection.update_one(
                {'email': email},
                {'$set': {
                    'password_hash': hashed_password,
                    'updated_at': datetime.utcnow()
                }}
            )
            
            if result.modified_count > 0:
                return {
                    'success': True,
                    'message': 'Password reset successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Doctor not found or no changes made'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Database error: {str(e)}'
            }