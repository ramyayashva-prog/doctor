#!/usr/bin/env python3
"""
Patient Alert System - MVC Architecture
Main application file with MVC structure
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import sys
from datetime import datetime, timedelta
import threading
import time

# Load environment variables from .env file
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("⚠️ python-dotenv not installed. Install with: pip install python-dotenv")

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import MVC components
from models.database import Database
from models.doctor_model import DoctorModel
from models.patient_model import PatientModel
from models.otp_model import OTPModel
from controllers.auth_controller import AuthController
from controllers.doctor_controller import DoctorController
from controllers.patient_controller import PatientController
from controllers.otp_controller import OTPController
from services.email_service import EmailService
from services.jwt_service import JWTService
from utils.validators import Validators
from utils.helpers import Helpers

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
class Config:
    MONGODB_URI = os.environ.get('MONGODB_URI')
    DATABASE_NAME = os.environ.get('DATABASE_NAME')
    SENDER_EMAIL = os.environ.get('SENDER_EMAIL')
    SENDER_PASSWORD = os.environ.get('SENDER_PASSWORD')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY')
    JWT_ALGORITHM = os.environ.get('JWT_ALGORITHM')

app.config.from_object(Config)

# Initialize services
db = Database()
# Ensure database connection is established
db.connect()

email_service = EmailService()
jwt_service = JWTService()
# voice_service = VoiceService()  # Removed voice functionality
validators = Validators()
helpers = Helpers()

# Initialize models
doctor_model = DoctorModel(db)
patient_model = PatientModel(db)
otp_model = OTPModel(db)

# Initialize controllers
auth_controller = AuthController(doctor_model, patient_model, otp_model, jwt_service, email_service, validators)
doctor_controller = DoctorController(doctor_model, jwt_service, validators)
patient_controller = PatientController()
otp_controller = OTPController(otp_model, jwt_service, email_service, validators)
# voice_controller = VoiceController()  # Removed voice functionality

# Routes
@app.route('/', methods=['GET'])
def root_endpoint():
    """Root endpoint with API information"""
    return jsonify({
        'message': 'Doctor Patient Management API',
        'version': '1.0.0',
        'status': 'running',
        'timestamp': datetime.now().isoformat(),
        'endpoints': {
            'health': '/health',
            'patients': '/patients',
            'doctors': '/doctors',
            'auth': '/doctor-login',
            'ai_summary': '/doctor/patient/{patient_id}/ai-summary',
            'debug': '/debug/openai-config'
        },
        'documentation': 'See API documentation for detailed endpoint usage'
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    })

# Debug endpoints for OpenAI configuration
@app.route('/debug/openai-config', methods=['GET'])
def debug_openai_config():
    """Debug OpenAI API key configuration"""
    try:
        import os
        
        # Check environment variables
        api_key = os.getenv('OPENAI_API_KEY')
        
        debug_info = {
            'openai_api_key_present': bool(api_key),
            'openai_api_key_format': f"{api_key[:10]}...{api_key[-4:]}" if api_key else None,
            'openai_api_key_valid_format': api_key.startswith('sk-') if api_key else False,
            'environment_vars': {k: v for k, v in os.environ.items() if 'OPENAI' in k or 'API' in k},
            'python_path': os.getcwd(),
            'environment': os.getenv('ENVIRONMENT', 'development')
        }
        
        return jsonify({
            'success': True,
            'debug_info': debug_info,
            'message': 'OpenAI configuration debug info'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'Debug failed'
        }), 500

@app.route('/debug/test-openai', methods=['GET'])
def test_openai_api():
    """Test OpenAI API connection"""
    try:
        import os
        from openai import OpenAI
        
        # Check OpenAI library version
        try:
            import openai
            openai_version = openai.__version__
        except:
            openai_version = "Unknown"
        
        # Get API key
        api_key = os.getenv('OPENAI_API_KEY')
        
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'OPENAI_API_KEY not found in environment variables',
                'message': 'Please set OPENAI_API_KEY in your environment',
                'openai_version': openai_version
            }), 400
        
        if not api_key.startswith('sk-'):
            return jsonify({
                'success': False,
                'error': 'Invalid API key format (should start with sk-)',
                'message': 'Please check your OpenAI API key',
                'openai_version': openai_version
            }), 400
        
        # Simple OpenAI client initialization for version 1.3.0
        try:
            import openai
            openai.api_key = api_key
            print('✅ OpenAI client initialized with simple method')
        except Exception as client_error:
            return jsonify({
                'success': False,
                'error': f'Failed to initialize OpenAI client: {str(client_error)}',
                'message': 'OpenAI client initialization failed',
                'error_type': type(client_error).__name__
            }), 500
        
        # Test API connection with simple method
        try:
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful assistant."},
                    {"role": "user", "content": "Say 'Hello, OpenAI API is working!'"}
                ],
                max_tokens=50,
                temperature=0.3
            )
            print('✅ OpenAI API call successful')
                
        except Exception as api_error:
            return jsonify({
                'success': False,
                'error': f'OpenAI API call failed: {str(api_error)}',
                'message': 'OpenAI API test failed',
                'error_type': type(api_error).__name__
            }), 500
        
        return jsonify({
            'success': True,
            'openai_response': response.choices[0].message.content,
            'model_used': response.model,
            'tokens_used': response.usage.total_tokens,
            'message': 'OpenAI API test successful',
            'openai_version': openai_version
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'OpenAI API test failed'
        }), 500

# Authentication Routes
@app.route('/doctor-signup', methods=['POST'])
def doctor_signup():
    """Doctor signup endpoint"""
    return auth_controller.doctor_signup(request)

@app.route('/doctor-send-otp', methods=['POST'])
def doctor_send_otp():
    """Send OTP to doctor email"""
    return otp_controller.doctor_send_otp(request)

@app.route('/doctor-verify-otp', methods=['POST'])
def doctor_verify_otp():
    """Verify doctor OTP"""
    return otp_controller.doctor_verify_otp(request)

@app.route('/resend-otp', methods=['POST'])
def resend_otp():
    """Resend OTP"""
    return otp_controller.resend_otp(request)

# Doctor Routes
@app.route('/doctor/profile/<doctor_id>', methods=['GET'])
def get_doctor_profile(doctor_id):
    """Get doctor profile"""
    return doctor_controller.get_profile(doctor_id)

@app.route('/doctor/profile/<doctor_id>', methods=['PUT'])
def update_doctor_profile(doctor_id):
    """Update doctor profile"""
    return doctor_controller.update_profile(doctor_id, request)

@app.route('/doctor/complete-profile', methods=['POST'])
def complete_doctor_profile():
    """Complete doctor profile"""
    return doctor_controller.complete_profile(request)

# Public doctor endpoints for patient selection
@app.route('/doctors', methods=['GET'])
def get_all_doctors():
    """Get all doctors list for patient selection"""
    return doctor_controller.get_all_doctors(request)

@app.route('/doctors/search', methods=['GET'])
def search_doctors():
    """Search doctors with filters for patient selection"""
    return doctor_controller.get_all_doctors(request)

@app.route('/doctors/<doctor_id>', methods=['GET'])
def get_public_doctor_profile(doctor_id):
    """Get public doctor profile for patient selection"""
    return doctor_controller.get_public_doctor_profile(doctor_id)

# Kebab-case endpoints for Flutter app compatibility
@app.route('/doctor-reset-password', methods=['POST'])
def doctor_reset_password():
    """Reset doctor password - kebab-case endpoint"""
    return auth_controller.doctor_reset_password(request)

@app.route('/doctor-forgot-password', methods=['POST'])
def doctor_forgot_password():
    """Forgot doctor password - kebab-case endpoint"""
    return auth_controller.doctor_forgot_password(request)

@app.route('/doctor-complete-profile', methods=['POST'])
def doctor_complete_profile_kebab():
    """Complete doctor profile - kebab-case endpoint"""
    return doctor_controller.complete_profile(request)

@app.route('/doctor-profile-fields', methods=['GET'])
def doctor_profile_fields():
    """Get doctor profile fields - kebab-case endpoint"""
    return doctor_controller.get_profile_fields(request)

@app.route('/complete-profile', methods=['POST'])
def complete_profile():
    """Complete profile - generic endpoint for Flutter compatibility"""
    return doctor_controller.complete_profile(request)

@app.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset password - generic endpoint for Flutter compatibility"""
    return auth_controller.doctor_reset_password(request)

@app.route('/doctor/patients', methods=['GET'])
def get_doctor_patients():
    """Get patients list for doctor"""
    return doctor_controller.get_patients(request)

@app.route('/doctor/patient/<patient_id>', methods=['GET'])
def get_doctor_patient_details(patient_id):
    """Get detailed patient information for doctor"""
    return doctor_controller.get_patient_details(request, patient_id)

@app.route('/doctor/patient/<patient_id>/full-details', methods=['GET'])
def get_patient_full_details(patient_id):
    """Get complete patient details with all health data"""
    return doctor_controller.get_patient_full_details(request, patient_id)

@app.route('/doctor/patient/<patient_id>/ai-summary', methods=['GET'])
def get_patient_ai_summary(patient_id):
    """Get AI-powered medical summary for a patient"""
    return doctor_controller.get_patient_ai_summary(request, patient_id)

@app.route('/doctor/appointments', methods=['GET'])
def get_doctor_appointments():
    """Get appointments for doctor"""
    return doctor_controller.get_appointments(request)

@app.route('/doctor/appointments', methods=['POST'])
def create_doctor_appointment():
    """Create new appointment for doctor"""
    return doctor_controller.create_appointment(request)

@app.route('/doctor/appointments/<appointment_id>', methods=['PUT'])
def update_doctor_appointment(appointment_id):
    """Update appointment for doctor"""
    return doctor_controller.update_appointment(request, appointment_id)

@app.route('/doctor/appointments/<appointment_id>', methods=['DELETE'])
def delete_doctor_appointment(appointment_id):
    """Delete appointment for doctor"""
    return doctor_controller.delete_appointment(request, appointment_id)

@app.route('/doctor/dashboard-stats', methods=['GET'])
def get_doctor_dashboard_stats():
    """Get dashboard statistics for doctor"""
    return doctor_controller.get_dashboard_stats(request)

# Patient Health Data Endpoints
@app.route('/medication/get-medication-history/<patient_id>', methods=['GET'])
def get_medication_history(patient_id):
    """Get medication history for patient"""
    return doctor_controller.get_medication_history(request, patient_id)

@app.route('/symptoms/get-analysis-reports/<patient_id>', methods=['GET'])
def get_symptom_analysis_reports(patient_id):
    """Get symptom analysis reports for patient"""
    return doctor_controller.get_symptom_analysis_reports(request, patient_id)

@app.route('/nutrition/get-food-entries/<patient_id>', methods=['GET'])
def get_food_entries(patient_id):
    """Get food entries for patient"""
    return doctor_controller.get_food_entries(request, patient_id)

@app.route('/medication/get-tablet-tracking-history/<patient_id>', methods=['GET'])
def get_tablet_tracking_history(patient_id):
    """Get tablet tracking history for patient"""
    return doctor_controller.get_tablet_tracking_history(request, patient_id)

@app.route('/profile/<patient_id>', methods=['GET'])
def get_patient_profile(patient_id):
    """Get patient profile"""
    return doctor_controller.get_patient_profile(request, patient_id)

@app.route('/kick-count/get-kick-history/<patient_id>', methods=['GET'])
def get_kick_count_history(patient_id):
    """Get kick count history for patient"""
    return doctor_controller.get_kick_count_history(request, patient_id)

@app.route('/mental-health/history/<patient_id>', methods=['GET'])
def get_mental_health_history(patient_id):
    """Get mental health history for patient"""
    return doctor_controller.get_mental_health_history(request, patient_id)

@app.route('/prescription/documents/<patient_id>', methods=['GET'])
def get_prescription_documents(patient_id):
    """Get prescription documents for patient"""
    return doctor_controller.get_prescription_documents(request, patient_id)

@app.route('/vital-signs/history/<patient_id>', methods=['GET'])
def get_vital_signs_history(patient_id):
    """Get vital signs history for patient"""
    return doctor_controller.get_vital_signs_history(request, patient_id)

# Patient Routes
@app.route('/patient/signup', methods=['POST'])
def patient_signup():
    """Patient signup"""
    return auth_controller.patient_signup(request)

@app.route('/patient/verify-otp', methods=['POST'])
def patient_verify_otp():
    """Verify patient OTP"""
    return otp_controller.patient_verify_otp(request)

# Patient CRUD Routes
@app.route('/patients', methods=['POST'])
def create_patient():
    """Create a new patient"""
    return patient_controller.create_patient(request)

@app.route('/patients', methods=['GET'])
def get_all_patients():
    """Get all patients with pagination and search"""
    return patient_controller.get_all_patients(request)

@app.route('/patients/<patient_id>', methods=['GET'])
def get_patient(patient_id):
    """Get patient by ID"""
    return patient_controller.get_patient(request, patient_id)

@app.route('/patients/<patient_id>', methods=['PUT'])
def update_patient(patient_id):
    """Update patient"""
    return patient_controller.update_patient(request, patient_id)

@app.route('/patients/<patient_id>', methods=['DELETE'])
def delete_patient(patient_id):
    """Delete patient"""
    return patient_controller.delete_patient(request, patient_id)

@app.route('/doctors/<doctor_id>/patients', methods=['GET'])
def get_patients_by_doctor(doctor_id):
    """Get all patients assigned to a specific doctor"""
    return patient_controller.get_patients_by_doctor(request, doctor_id)

@app.route('/login', methods=['POST'])
def login():
    """Login endpoint for both doctors and patients"""
    return auth_controller.login(request)

@app.route('/doctor-login', methods=['POST'])
def doctor_login():
    """Doctor-only login endpoint"""
    return auth_controller.doctor_login(request)

# Voice Dictation Routes - REMOVED (voice functionality disabled)
# All voice-related endpoints have been removed to fix deployment issues

# Error Handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(400)
def bad_request(error):
    return jsonify({'error': 'Bad request'}), 400

# Initialize database connection
def initialize_database():
    """Initialize database connection"""
    try:
        if db.connect():
            print("✅ Database connected successfully")
            return True
        else:
            print("❌ Database connection failed")
            return False
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

# Main application
if __name__ == '__main__':
    print("🚀 Starting Patient Alert System - MVC Architecture")
    print("=" * 60)
    
    # Initialize database
    if not initialize_database():
        print("❌ Failed to initialize database. Exiting...")
        sys.exit(1)
    
    # Start the application
    port = int(os.environ.get('PORT', 5000))
    debug_mode = os.environ.get('FLASK_ENV', 'development') != 'production'
    
    print(f"📱 API will be available at: http://localhost:{port}")
    print(f"🌐 Debug mode: {debug_mode}")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=port, debug=debug_mode)

# Debug endpoints for troubleshooting authentication issues
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
