"""
Debug endpoints to troubleshoot Render deployment issues
Add these to your app_mvc.py for debugging
"""

from flask import jsonify
import os

@app.route('/debug/env', methods=['GET'])
def debug_environment():
    """Debug environment variables"""
    return jsonify({
        'mongodb_uri_set': bool(os.environ.get('MONGODB_URI')),
        'database_name_set': bool(os.environ.get('DATABASE_NAME')),
        'jwt_secret_set': bool(os.environ.get('JWT_SECRET_KEY')),
        'sender_email_set': bool(os.environ.get('SENDER_EMAIL')),
        'database_name': os.environ.get('DATABASE_NAME', 'NOT_SET'),
        'mongodb_uri_prefix': os.environ.get('MONGODB_URI', 'NOT_SET')[:20] + '...' if os.environ.get('MONGODB_URI') else 'NOT_SET'
    })

@app.route('/debug/db', methods=['GET'])
def debug_database():
    """Debug database connection"""
    try:
        # Test database connection
        if db.is_connected:
            # Try to get a doctor count
            doctor_count = db.doctors_collection.count_documents({})
            return jsonify({
                'status': 'connected',
                'doctor_count': doctor_count,
                'database_name': db.db.name,
                'collections': list(db.db.list_collection_names())
            })
        else:
            return jsonify({
                'status': 'not_connected',
                'error': 'Database not connected'
            })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e)
        })

@app.route('/debug/doctors', methods=['GET'])
def debug_doctors():
    """Debug doctor data"""
    try:
        doctors = list(db.doctors_collection.find({}, {'username': 1, 'email': 1, 'doctor_id': 1, 'role': 1, '_id': 0}))
        return jsonify({
            'doctor_count': len(doctors),
            'doctors': doctors[:5]  # Show first 5 doctors
        })
    except Exception as e:
        return jsonify({
            'error': str(e)
        })

@app.route('/debug/test-login', methods=['POST'])
def debug_test_login():
    """Debug test login with specific credentials"""
    try:
        data = request.get_json()
        email = data.get('email', '')
        password = data.get('password', '')
        
        # Find doctor
        doctor = db.doctors_collection.find_one({'email': email})
        
        if not doctor:
            return jsonify({
                'found': False,
                'error': 'Doctor not found',
                'searched_email': email
            })
        
        # Check if password_hash exists
        has_password_hash = 'password_hash' in doctor
        
        return jsonify({
            'found': True,
            'doctor_id': doctor.get('doctor_id'),
            'username': doctor.get('username'),
            'email': doctor.get('email'),
            'has_password_hash': has_password_hash,
            'role': doctor.get('role')
        })
        
    except Exception as e:
        return jsonify({
            'error': str(e)
        })
