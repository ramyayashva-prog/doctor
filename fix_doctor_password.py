#!/usr/bin/env python3
"""
Quick fix for doctor password issue
"""

import sys
import os

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models.database import Database
from models.doctor_model import DoctorModel

def fix_doctor_password():
    """Fix the password for existing doctor"""
    
    # Initialize database
    db = Database()
    db.connect()
    
    if not db.is_connected:
        print("❌ Failed to connect to database")
        return False
    
    # Initialize doctor model
    doctor_model = DoctorModel(db)
    
    # Your existing doctor details
    email = "ramyayashva@gmail.com"
    new_password = "Ramya@1"  # Your current password
    
    try:
        print(f"🔍 Fixing password for: {email}")
        
        # Find the doctor
        doctor = doctor_model.get_doctor_by_email(email)
        
        if not doctor:
            print(f"❌ Doctor not found with email: {email}")
            return False
        
        print(f"✅ Found doctor: {doctor['username']} ({doctor['doctor_id']})")
        
        # Check current password hash type
        current_hash = doctor.get('password_hash')
        print(f"🔍 Current password hash type: {type(current_hash)}")
        
        # Hash the new password using our corrected method
        password_hash = doctor_model._hash_password(new_password)
        print(f"🔍 New password hash type: {type(password_hash)}")
        
        # Update the password in database
        result = db.doctors_collection.update_one(
            {'email': email},
            {'$set': {'password_hash': password_hash}}
        )
        
        if result.modified_count > 0:
            print(f"✅ Password updated successfully for {email}")
            print(f"   New password: {new_password}")
            
            # Test password verification immediately
            print("🔍 Testing new password...")
            password_valid = doctor_model.verify_password(email, new_password)
            print(f"   Password verification: {'✅ Valid' if password_valid else '❌ Invalid'}")
            
            if password_valid:
                print("🎉 SUCCESS! You can now login with:")
                print(f"   Email: {email}")
                print(f"   Password: {new_password}")
                return True
            else:
                print("❌ Password verification still failing")
                return False
        else:
            print("❌ Failed to update password")
            return False
            
    except Exception as e:
        print(f"❌ Error fixing password: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🚀 Quick Doctor Password Fix")
    print("=" * 40)
    
    success = fix_doctor_password()
    
    if success:
        print("\n✅ Password fixed successfully!")
        print("You can now login to your application.")
    else:
        print("\n❌ Password fix failed!")
        print("Please check the error messages above.")
