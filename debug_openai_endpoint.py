#!/usr/bin/env python3
"""
Debug OpenAI Configuration Endpoint

This creates a debug endpoint to test OpenAI API key configuration
and help diagnose issues with the AI summary functionality.
"""

from flask import Flask, jsonify, request
import os
from dotenv import load_dotenv

# Create Flask app for debugging
debug_app = Flask(__name__)

@debug_app.route('/debug/openai-config', methods=['GET'])
def debug_openai_config():
    """Debug OpenAI API key configuration"""
    try:
        # Load environment variables
        load_dotenv()
        
        # Check environment variables
        api_key = os.getenv('OPENAI_API_KEY')
        
        debug_info = {
            'openai_api_key_present': bool(api_key),
            'openai_api_key_format': f"{api_key[:10]}...{api_key[-4:]}" if api_key else None,
            'openai_api_key_valid_format': api_key.startswith('sk-') if api_key else False,
            'all_env_vars': {k: v for k, v in os.environ.items() if 'OPENAI' in k or 'API' in k},
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

@debug_app.route('/debug/test-openai', methods=['GET'])
def test_openai_api():
    """Test OpenAI API connection"""
    try:
        import os
        from openai import OpenAI
        
        # Get API key
        api_key = os.getenv('OPENAI_API_KEY')
        
        if not api_key:
            return jsonify({
                'success': False,
                'error': 'OPENAI_API_KEY not found in environment variables',
                'message': 'Please set OPENAI_API_KEY in your environment'
            }), 400
        
        if not api_key.startswith('sk-'):
            return jsonify({
                'success': False,
                'error': 'Invalid API key format (should start with sk-)',
                'message': 'Please check your OpenAI API key'
            }), 400
        
        # Initialize OpenAI client
        client = OpenAI(api_key=api_key)
        
        # Test API connection with a simple request
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Say 'Hello, OpenAI API is working!'"}
            ],
            max_tokens=50,
            temperature=0.3
        )
        
        return jsonify({
            'success': True,
            'openai_response': response.choices[0].message.content,
            'model_used': response.model,
            'tokens_used': response.usage.total_tokens,
            'message': 'OpenAI API test successful'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'OpenAI API test failed'
        }), 500

@debug_app.route('/debug/test-patient-data', methods=['GET'])
def test_patient_data_formatting():
    """Test patient data formatting for OpenAI"""
    try:
        # Sample patient data
        sample_patient_data = {
            'success': True,
            'patient_id': 'TEST_PATIENT_001',
            'patient_info': {
                'full_name': 'Test Patient',
                'email': 'test@example.com',
                'age': 30,
                'blood_type': 'O+',
                'gender': 'Male',
                'is_pregnant': False,
                'status': 'Active'
            },
            'health_data': {
                'food_data': [
                    {'food_input': 'Oatmeal with fruits', 'meal_type': 'Breakfast'},
                    {'food_input': 'Grilled chicken salad', 'meal_type': 'Lunch'}
                ],
                'symptom_analysis_reports': [
                    {'symptom_text': 'Headache and fatigue', 'severity': 'Moderate'}
                ],
                'mental_health_logs': [
                    {'mood': 'Good', 'date': '2025-09-28'}
                ],
                'appointments': [
                    {'appointment_type': 'Regular Checkup', 'appointment_date': '2025-09-30'}
                ]
            },
            'summary': {
                'total_appointments': 1,
                'total_food_entries': 2,
                'total_symptoms': 1,
                'total_mental_health': 1,
                'total_medications': 0
            }
        }
        
        # Format the data (similar to the actual method)
        formatted_data = f"""
PATIENT SUMMARY REPORT
=====================

PATIENT INFORMATION:
- Name: {sample_patient_data['patient_info']['full_name']}
- Email: {sample_patient_data['patient_info']['email']}
- Age: {sample_patient_data['patient_info']['age']}
- Blood Type: {sample_patient_data['patient_info']['blood_type']}
- Gender: {sample_patient_data['patient_info']['gender']}
- Pregnant: {sample_patient_data['patient_info']['is_pregnant']}
- Status: {sample_patient_data['patient_info']['status']}

HEALTH DATA SUMMARY:
- Total Appointments: {sample_patient_data['summary']['total_appointments']}
- Food & Nutrition Entries: {sample_patient_data['summary']['total_food_entries']}
- Symptom Analysis Reports: {sample_patient_data['summary']['total_symptoms']}
- Mental Health Logs: {sample_patient_data['summary']['total_mental_health']}
- Medication History: {sample_patient_data['summary']['total_medications']}

DETAILED HEALTH INFORMATION:
"""
        
        # Add detailed health data
        if sample_patient_data['health_data'].get('food_data'):
            formatted_data += "\nFOOD & NUTRITION LOGS:\n"
            for food in sample_patient_data['health_data']['food_data']:
                formatted_data += f"- {food.get('food_input', 'N/A')} ({food.get('meal_type', 'N/A')})\n"
        
        if sample_patient_data['health_data'].get('symptom_analysis_reports'):
            formatted_data += "\nSYMPTOM ANALYSIS REPORTS:\n"
            for symptom in sample_patient_data['health_data']['symptom_analysis_reports']:
                formatted_data += f"- {symptom.get('symptom_text', 'N/A')} (Severity: {symptom.get('severity', 'N/A')})\n"
        
        return jsonify({
            'success': True,
            'sample_patient_data': sample_patient_data,
            'formatted_data_preview': formatted_data[:500] + "...",
            'formatted_data_length': len(formatted_data),
            'message': 'Patient data formatting test successful'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'Patient data formatting test failed'
        }), 500

if __name__ == '__main__':
    debug_app.run(debug=True, port=5001)
