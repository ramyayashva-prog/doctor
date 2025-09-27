#!/usr/bin/env python3
"""
Create a test doctor with known credentials for testing
"""

import sys
import os

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models.database import Database
from models.doctor_model import DoctorModel

def create_test_doctor():
    """Create a test doctor with known credentials"""
    
    # Initialize database
    db = Database()
    db.connect()
    
    if not db.is_connected:
        print("❌ Failed to connect to database")
        return False
    
    # Initialize doctor model
    doctor_model = DoctorModel(db)
    
    # Test doctor data
    test_doctor = {
        'username': 'testdoctor',
        'email': 'testdoctor@example.com',
        'mobile': '9876543210',
        'password': 'testpass123',
        'role': 'doctor'
    }
    
    try:
        print("🔍 Checking if test doctor already exists...")
        
        # Check if doctor already exists
        existing_doctor = doctor_model.get_doctor_by_email(test_doctor['email'])
        
        if existing_doctor:
            print(f"✅ Test doctor already exists: {existing_doctor['username']} ({existing_doctor['doctor_id']})")
            
            # Test password verification
            print("🔍 Testing password verification...")
            password_valid = doctor_model.verify_password(test_doctor['email'], test_doctor['password'])
            print(f"   Password verification: {'✅ Valid' if password_valid else '❌ Invalid'}")
            
            return True
        
        # Create new test doctor
        print("👤 Creating new test doctor...")
        result = doctor_model.create_doctor(test_doctor)
        
        if result['success']:
            print(f"✅ Test doctor created successfully!")
            print(f"   Doctor ID: {result['doctor_id']}")
            print(f"   Username: {test_doctor['username']}")
            print(f"   Email: {test_doctor['email']}")
            print(f"   Password: {test_doctor['password']}")
            
            # Test password verification immediately
            print("🔍 Testing password verification...")
            password_valid = doctor_model.verify_password(test_doctor['email'], test_doctor['password'])
            print(f"   Password verification: {'✅ Valid' if password_valid else '❌ Invalid'}")
            
            return True
        else:
            print(f"❌ Failed to create test doctor: {result.get('error', 'Unknown error')}")
            return False
            
    except Exception as e:
        print(f"❌ Error creating test doctor: {e}")
        import traceback
        traceback.print_exc()
        return False

def reset_existing_doctor():
    """Reset password for existing doctor"""
    
    # Initialize database
    db = Database()
    db.connect()
    
    if not db.is_connected:
        print("❌ Failed to connect to database")
        return False
    
    # Initialize doctor model
    doctor_model = DoctorModel(db)
    
    email = input("Enter doctor email to reset password: ").strip()
    new_password = input("Enter new password: ").strip()
    
    if not email or not new_password:
        print("❌ Email and password are required")
        return False
    
    try:
        # Find the doctor
        doctor = doctor_model.get_doctor_by_email(email)
        
        if not doctor:
            print(f"❌ Doctor not found with email: {email}")
            return False
        
        print(f"✅ Found doctor: {doctor['username']} ({doctor['doctor_id']})")
        
        # Hash the new password
        password_hash = doctor_model._hash_password(new_password)
        
        # Update the password
        result = db.doctors_collection.update_one(
            {'email': email},
            {'$set': {'password_hash': password_hash}}
        )
        
        if result.modified_count > 0:
            print(f"✅ Password updated successfully for {email}")
            print(f"   New password: {new_password}")
            
            # Test password verification
            print("🔍 Testing new password...")
            password_valid = doctor_model.verify_password(email, new_password)
            print(f"   Password verification: {'✅ Valid' if password_valid else '❌ Invalid'}")
            
            return True
        else:
            print("❌ Failed to update password")
            return False
            
    except Exception as e:
        print(f"❌ Error resetting password: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🚀 Doctor Password Management Tool")
    print("=" * 40)
    
    choice = input("Choose an option:\n1. Create test doctor\n2. Reset existing doctor password\nEnter choice (1 or 2): ").strip()
    
    if choice == "1":
        create_test_doctor()
    elif choice == "2":
        reset_existing_doctor()
    else:
        print("❌ Invalid choice")
    
    print("\n✅ Operation completed!")
