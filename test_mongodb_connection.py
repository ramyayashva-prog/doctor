#!/usr/bin/env python3
"""
Test MongoDB Connection
"""

import pymongo
from pymongo import MongoClient
import os

def test_mongodb_connection():
    """Test MongoDB Atlas connection"""
    print("🧪 Testing MongoDB Atlas Connection")
    print("=" * 50)
    
    # MongoDB URI from your code
    mongodb_uri = 'mongodb+srv://ramya:XxFn6n0NXx0wBplV@cluster0.c1g1bm5.mongodb.net'
    database_name = 'patients_db'
    
    print(f"🔍 URI: {mongodb_uri}")
    print(f"🔍 Database: {database_name}")
    print()
    
    try:
        print("🔄 Attempting to connect...")
        client = MongoClient(
            mongodb_uri,
            serverSelectionTimeoutMS=10000,  # 10 seconds
            connectTimeoutMS=10000,         # 10 seconds
            socketTimeoutMS=10000,          # 10 seconds
        )
        
        # Test connection
        client.admin.command('ping')
        print("✅ MongoDB connection successful!")
        
        # Test database access
        db = client[database_name]
        collections = db.list_collection_names()
        print(f"✅ Database '{database_name}' accessible")
        print(f"📊 Collections: {collections}")
        
        client.close()
        return True
        
    except pymongo.errors.NetworkTimeout as e:
        print(f"❌ Network timeout: {e}")
        print("💡 Solutions:")
        print("   1. Check your internet connection")
        print("   2. Add your IP to MongoDB Atlas whitelist")
        print("   3. Try again in a few minutes")
        return False
        
    except pymongo.errors.ServerSelectionTimeoutError as e:
        print(f"❌ Server selection timeout: {e}")
        print("💡 Solutions:")
        print("   1. Check if MongoDB Atlas cluster is running")
        print("   2. Verify the connection string")
        print("   3. Check IP whitelist settings")
        return False
        
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False

if __name__ == "__main__":
    test_mongodb_connection()
