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
from controllers.voice_controller import VoiceController
from services.email_service import EmailService
from services.jwt_service import JWTService
from services.voice_service import VoiceService
from utils.validators import Validators
from utils.helpers import Helpers

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
class Config:
    MONGODB_URI = os.environ.get('MONGODB_URI', 'mongodb+srv://ramya:XxFn6n0NXx0wBplV@cluster0.c1g1bm5.mongodb.net')
    DATABASE_NAME = os.environ.get('DATABASE_NAME', 'patients_db')
    SENDER_EMAIL = os.environ.get('SENDER_EMAIL', 'ramya.sureshkumar.lm@gmail.com')
    SENDER_PASSWORD = os.environ.get('SENDER_PASSWORD', 'djqs dktf gqor gnqg')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', '27982af8380786e1f2967dca145cc0ed')
    JWT_ALGORITHM = os.environ.get('JWT_ALGORITHM', 'HS256')

app.config.from_object(Config)

# Initialize services
db = Database()
# Ensure database connection is established
db.connect()

email_service = EmailService()
jwt_service = JWTService()
voice_service = VoiceService()
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
voice_controller = VoiceController()

# Routes
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    })

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

# Voice Dictation Routes
@app.route('/voice/conversations', methods=['POST'])
def create_voice_conversation():
    """Create a new voice conversation"""
    data = request.get_json()
    return voice_controller.create_conversation(request, data)

@app.route('/voice/conversations/<conversation_id>', methods=['GET'])
def get_voice_conversation(conversation_id):
    """Get voice conversation by ID"""
    return voice_controller.get_conversation(request, conversation_id)

@app.route('/voice/conversations/patient/<patient_id>', methods=['GET'])
def get_patient_voice_conversations(patient_id):
    """Get all voice conversations for a patient"""
    return voice_controller.get_patient_conversations(request, patient_id)

@app.route('/voice/conversations/<conversation_id>', methods=['PUT'])
def update_voice_conversation(conversation_id):
    """Update voice conversation"""
    data = request.get_json()
    return voice_controller.update_conversation(request, conversation_id, data)

@app.route('/voice/conversations/<conversation_id>', methods=['DELETE'])
def delete_voice_conversation(conversation_id):
    """Delete voice conversation"""
    return voice_controller.delete_conversation(request, conversation_id)

@app.route('/voice/transcriptions', methods=['POST'])
def create_voice_transcription():
    """Create a new voice transcription"""
    data = request.get_json()
    return voice_controller.create_transcription(request, data)

@app.route('/voice/transcriptions/<transcription_id>', methods=['GET'])
def get_voice_transcription(transcription_id):
    """Get voice transcription by ID"""
    return voice_controller.get_transcription(request, transcription_id)

@app.route('/voice/transcriptions/conversation/<conversation_id>', methods=['GET'])
def get_conversation_transcriptions(conversation_id):
    """Get all transcriptions for a conversation"""
    return voice_controller.get_conversation_transcriptions(request, conversation_id)

@app.route('/voice/transcriptions/conversation/<conversation_id>/final', methods=['GET'])
def get_final_transcriptions(conversation_id):
    """Get only final transcriptions for a conversation"""
    return voice_controller.get_final_transcriptions(request, conversation_id)

@app.route('/voice/transcriptions/<transcription_id>', methods=['PUT'])
def update_voice_transcription(transcription_id):
    """Update voice transcription"""
    data = request.get_json()
    return voice_controller.update_transcription(request, transcription_id, data)

@app.route('/voice/transcriptions/<transcription_id>', methods=['DELETE'])
def delete_voice_transcription(transcription_id):
    """Delete voice transcription"""
    return voice_controller.delete_transcription(request, transcription_id)

@app.route('/voice/process-audio', methods=['POST'])
def process_audio_chunk():
    """Process audio chunk and return transcription"""
    try:
        data = request.get_json()
        conversation_id = data.get('conversation_id')
        chunk_index = data.get('chunk_index', 0)
        audio_data = data.get('audio_data')
        
        if not conversation_id or not audio_data:
            return jsonify({'error': 'Missing required fields: conversation_id, audio_data'}), 400
        
        # Process the audio chunk
        result, status_code = voice_controller.process_audio_chunk(request, audio_data, conversation_id, chunk_index)
        
        # Add additional metadata for better tracking
        if status_code == 200 and 'transcription' in result:
            result['transcription']['processing_timestamp'] = datetime.now().isoformat()
            result['transcription']['chunk_index'] = chunk_index
            result['transcription']['conversation_id'] = conversation_id
        
        return jsonify(result), status_code
        
    except Exception as e:
        return jsonify({'error': f'Audio processing failed: {str(e)}'}), 500

@app.route('/voice/conversations/<conversation_id>/summary', methods=['GET'])
def get_conversation_summary(conversation_id):
    """Get conversation summary with statistics"""
    summary = voice_service.get_conversation_summary(conversation_id)
    if 'error' in summary:
        return jsonify(summary), 404
    return jsonify(summary), 200

@app.route('/voice/conversations/<conversation_id>/status', methods=['GET'])
def get_conversation_status(conversation_id):
    """Get real-time conversation status and transcription progress"""
    try:
        # Get conversation details
        conversation_result, conv_status = voice_controller.get_conversation(request, conversation_id)
        if conv_status != 200:
            return jsonify({'error': 'Conversation not found'}), 404
        
        # Get transcriptions count
        transcriptions_result, trans_status = voice_controller.get_conversation_transcriptions(request, conversation_id)
        transcription_count = len(transcriptions_result.get('transcriptions', [])) if trans_status == 200 else 0
        
        # Get final transcriptions count
        final_result, final_status = voice_controller.get_final_transcriptions(request, conversation_id)
        final_count = len(final_result.get('transcriptions', [])) if final_status == 200 else 0
        
        return jsonify({
            'conversation_id': conversation_id,
            'status': 'active' if conversation_result.get('conversation', {}).get('is_active', False) else 'inactive',
            'transcription_count': transcription_count,
            'final_transcription_count': final_count,
            'last_updated': datetime.now().isoformat(),
            'ready_for_recording': True
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'Failed to get conversation status: {str(e)}'}), 500

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
