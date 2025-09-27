"""
Database Model - Handles all database operations
"""

import pymongo
from pymongo import MongoClient
import os
from datetime import datetime
import logging

class Database:
    """Database connection and operations"""
    
    def __init__(self):
        self.client = None
        self.db = None
        self.patients_collection = None
        self.doctors_collection = None
        self.mental_health_collection = None
        self.appointments_collection = None
        self.temp_otp_collection = None
        self.is_connected = False
        
    def connect(self, max_retries=3):
        """Connect to MongoDB with retry logic"""
        for attempt in range(max_retries):
            try:
                print(f"🔄 Connection attempt {attempt + 1}/{max_retries}")
                # Get MongoDB URI from environment
                mongodb_uri = os.environ.get('MONGODB_URI', 'mongodb+srv://ramya:XxFn6n0NXx0wBplV@cluster0.c1g1bm5.mongodb.net')
                database_name = os.environ.get('DATABASE_NAME', 'patients_db')
                
                print(f"🔍 Attempting to connect to MongoDB...")
                print(f"🔍 URI: {mongodb_uri}")
                print(f"🔍 Database: {database_name}")
                
                # Create MongoDB client with better connection parameters
                self.client = MongoClient(
                    mongodb_uri, 
                    serverSelectionTimeoutMS=30000,  # 30 seconds
                    connectTimeoutMS=30000,          # 30 seconds
                    socketTimeoutMS=30000,           # 30 seconds
                    retryWrites=True,
                    retryReads=True,
                    maxPoolSize=10,
                    minPoolSize=1
                )
                
                # Test connection
                self.client.admin.command('ping')
                print("✅ MongoDB connection test successful")
                
                # Get database
                self.db = self.client[database_name]
                print(f"✅ Database '{database_name}' accessed successfully")
                
                # Initialize collections
                self._initialize_collections()
                
                # Create indexes
                self._create_indexes()
                
                self.is_connected = True
                print("✅ Connected to MongoDB successfully")
                return True
                
            except Exception as e:
                print(f"❌ MongoDB connection failed (attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    print(f"⏳ Waiting 5 seconds before retry...")
                    import time
                    time.sleep(5)
                else:
                    print("🔍 Troubleshooting tips:")
                    print("   1. Check your internet connection")
                    print("   2. Verify MongoDB Atlas cluster is running")
                    print("   3. Check if your IP is whitelisted in MongoDB Atlas")
                    print("   4. Verify the connection string is correct")
                    print("   5. Try restarting your MongoDB Atlas cluster")
                    self.is_connected = False
                    return False
    
    def _initialize_collections(self):
        """Initialize all collections"""
        try:
            print("🔍 Testing collections...")
            
            # Patients collection
            self.patients_collection = self.db.Patient_test
            print("🔍 Patients collection: Patient_test")
            
            # Mental health collection
            self.mental_health_collection = self.db.mental_health_logs
            print("🔍 Mental health collection: mental_health_logs")
            
            # Doctors collection
            self.doctors_collection = self.db.doctor_v2
            print("🔍 Doctors collection: doctor_v2")
            
            # Appointments collection
            self.appointments_collection = self.db.appointments
            print("🔍 Appointments collection: appointments")
            
            # Temporary OTP collection
            self.temp_otp_collection = self.db.temp_otp_collection
            print("🔍 Temp OTP collection: temp_otp_collection")
            
            print("✅ All collections initialized")
            
        except Exception as e:
            print(f"❌ Collection initialization failed: {e}")
            raise
    
    def _create_indexes(self):
        """Create database indexes"""
        try:
            print("🔍 Creating indexes...")
            
            # Patient indexes
            if self.patients_collection is not None:
                try:
                    self.patients_collection.create_index("patient_id", unique=True)
                    print("✅ patient_id index created")
                except Exception as e:
                    print(f"⚠️ patient_id index creation failed: {e}")
                
                try:
                    self.patients_collection.create_index("email", unique=True, sparse=True)
                    print("✅ email index created")
                except Exception as e:
                    print(f"⚠️ email index creation failed: {e}")
                
                try:
                    self.patients_collection.create_index("mobile", unique=True, sparse=True)
                    print("✅ mobile index created")
                except Exception as e:
                    print(f"⚠️ mobile index creation failed: {e}")
            
            # Mental health indexes
            if self.mental_health_collection is not None:
                # Drop old indexes first
                try:
                    self.mental_health_collection.drop_indexes()
                    print("🔍 Dropping old mental health indexes...")
                    print("✅ Old indexes dropped")
                except:
                    pass
                
                self.mental_health_collection.create_index("patient_id")
                print("✅ mental_health patient_id index created")
                
                self.mental_health_collection.create_index("date")
                print("✅ mental_health date index created")
                
                self.mental_health_collection.create_index([("patient_id", 1), ("date", -1)])
                print("✅ mental_health compound index created (non-unique)")
            
            # Doctor indexes
            if self.doctors_collection is not None:
                try:
                    self.doctors_collection.create_index("doctor_id", unique=True)
                    print("✅ doctor_id index created")
                except Exception as e:
                    print(f"⚠️ doctor_id index creation failed: {e}")
                
                try:
                    self.doctors_collection.create_index("email", unique=True, sparse=True)
                    print("✅ doctor email index created")
                except Exception as e:
                    print(f"⚠️ doctor email index creation failed: {e}")
            
            print("✅ All indexes created successfully")
            
        except Exception as e:
            print(f"❌ Index creation failed: {e}")
            raise
    
    def disconnect(self):
        """Disconnect from MongoDB"""
        if self.client:
            self.client.close()
            self.is_connected = False
            print("✅ Disconnected from MongoDB")
    
    def get_collection(self, collection_name):
        """Get a specific collection"""
        if not self.is_connected:
            raise Exception("Database not connected")
        
        return self.db[collection_name]
    
    def is_healthy(self):
        """Check if database is healthy"""
        try:
            if not self.is_connected or not self.client:
                return False
            
            # Ping the database
            self.client.admin.command('ping')
            return True
        except:
            return False
