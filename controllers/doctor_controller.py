"""
Doctor Controller - Handles doctor operations
"""

from flask import request, jsonify
from typing import Dict, Any
from datetime import datetime
import sys
import os

# Add the parent directory to the path to import utils
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from utils.objectid_converter import convert_objectid_to_string

class DoctorController:
    """Doctor controller"""
    
    def __init__(self, doctor_model, jwt_service, validators):
        self.doctor_model = doctor_model
        self.jwt_service = jwt_service
        self.validators = validators
    
    def get_profile(self, doctor_id: str) -> tuple:
        """Get doctor profile"""
        try:
            if not doctor_id:
                return jsonify({'error': 'Doctor ID is required'}), 400
            
            doctor = self.doctor_model.get_doctor_by_id(doctor_id)
            if not doctor:
                return jsonify({'error': 'Doctor not found'}), 404
            
            return jsonify({
                'success': True,
                'doctor': doctor
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def update_profile(self, doctor_id: str, request) -> tuple:
        """Update doctor profile"""
        try:
            if not doctor_id:
                return jsonify({'error': 'Doctor ID is required'}), 400
            
            data = request.get_json()
            if not data:
                return jsonify({'error': 'No data provided'}), 400
            
            # Update doctor profile
            result = self.doctor_model.update_doctor_profile(doctor_id, data)
            
            if result['success']:
                return jsonify({
                    'success': True,
                    'message': result['message']
                }), 200
            else:
                return jsonify({'error': result['error']}), 400
                
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def complete_profile(self, request) -> tuple:
        """Complete doctor profile"""
        try:
            data = request.get_json()
            doctor_id = data.get('doctor_id', '').strip()
            
            if not doctor_id:
                return jsonify({'error': 'Doctor ID is required'}), 400
            
            # Complete doctor profile
            result = self.doctor_model.complete_doctor_profile(doctor_id, data)
            
            if result['success']:
                return jsonify({
                    'success': True,
                    'message': result['message']
                }), 200
            else:
                return jsonify({'error': result['error']}), 400
                
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def get_all_doctors(self, request) -> tuple:
        """Get all doctors list with patient count for patient selection"""
        try:
            # Get query parameters
            page = int(request.args.get('page', 1))
            limit = int(request.args.get('limit', 20))
            search = request.args.get('search', '').strip()
            specialization = request.args.get('specialization', '').strip()
            city = request.args.get('city', '').strip()
            min_patients = request.args.get('min_patients', '').strip()
            
            # Build query filter
            query_filter = {"status": {"$ne": "deleted"}}
            
            if search:
                query_filter["$or"] = [
                    {"username": {"$regex": search, "$options": "i"}},
                    {"first_name": {"$regex": search, "$options": "i"}},
                    {"last_name": {"$regex": search, "$options": "i"}},
                    {"email": {"$regex": search, "$options": "i"}},
                    {"specialization": {"$regex": search, "$options": "i"}}
                ]
            
            if specialization:
                query_filter["specialization"] = {"$regex": specialization, "$options": "i"}
                
            if city:
                query_filter["city"] = {"$regex": city, "$options": "i"}
            
            # Get doctors from database
            result = self.doctor_model.get_all_doctors(
                query_filter=query_filter,
                page=page,
                limit=limit
            )
            
            if result['success']:
                # Filter by minimum patients if specified
                doctors = result['doctors']
                if min_patients and min_patients.isdigit():
                    min_count = int(min_patients)
                    doctors = [doc for doc in doctors if doc.get('patient_count', 0) >= min_count]
                    
                return jsonify({
                    'success': True,
                    'doctors': doctors,
                    'total_count': result['total_count'],
                    'page': page,
                    'limit': limit,
                    'total_pages': result['total_pages'],
                    'filters_applied': {
                        'search': search,
                        'specialization': specialization,
                        'city': city,
                        'min_patients': min_patients
                    }
                }), 200
            else:
                return jsonify({'error': result['error']}), 500
                
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def get_public_doctor_profile(self, doctor_id: str) -> tuple:
        """Get public doctor profile for patient selection"""
        try:
            if not doctor_id:
                return jsonify({'error': 'Doctor ID is required'}), 400
            
            doctor = self.doctor_model.get_doctor_by_id(doctor_id)
            if not doctor:
                return jsonify({'error': 'Doctor not found'}), 404
            
            # Get patient count
            patient_count = self.doctor_model._count_patients_for_doctor(doctor_id)
            
            # Prepare public profile (exclude sensitive data)
            public_profile = {
                'doctor_id': doctor.get('doctor_id'),
                'username': doctor.get('username'),
                'first_name': doctor.get('first_name'),
                'last_name': doctor.get('last_name'),
                'specialization': doctor.get('specialization'),
                'experience_years': doctor.get('experience_years'),
                'license_number': doctor.get('license_number'),
                'hospital_name': doctor.get('hospital_name'),
                'address': doctor.get('address'),
                'city': doctor.get('city'),
                'state': doctor.get('state'),
                'pincode': doctor.get('pincode'),
                'consultation_fee': doctor.get('consultation_fee'),
                'languages': doctor.get('languages', []),
                'qualifications': doctor.get('qualifications', []),
                'patient_count': patient_count,
                'status': doctor.get('status'),
                'created_at': doctor.get('created_at'),
                'is_profile_complete': doctor.get('is_profile_complete')
            }
            
            return jsonify({
                'success': True,
                'doctor': public_profile
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def get_patients(self, request) -> tuple:
        """Get patients list for doctor"""
        try:
            # For doctor-only app, we don't need to validate doctor_id
            # Just get all patients from the database using the working logic from app_simple.py
            if hasattr(self.doctor_model, 'db') and hasattr(self.doctor_model.db, 'patients_collection'):
                patients_collection = self.doctor_model.db.patients_collection
                
                # Get all active patients (using the same logic as app_simple.py)
                patients = list(patients_collection.find(
                    {"status": {"$ne": "deleted"}},
                    {
                        "patient_id": 1,
                        "username": 1,
                        "email": 1,
                        "first_name": 1,
                        "last_name": 1,
                        "date_of_birth": 1,
                        "blood_type": 1,
                        "mobile": 1,
                        "is_pregnant": 1,
                        "is_profile_complete": 1,
                        "created_at": 1,
                        "last_login": 1,
                        "status": 1,
                        "age": 1,
                        "gender": 1,
                        "address": 1,
                        "city": 1,
                        "state": 1,
                        "pincode": 1
                    }
                ))
                
                # Format patient data (using the same logic as app_simple.py)
                formatted_patients = []
                for patient in patients:
                    formatted_patients.append({
                        "patient_id": patient.get("patient_id", ""),
                        "name": f"{patient.get('first_name', '')} {patient.get('last_name', '')}".strip() or patient.get('username', 'Unknown'),
                        "email": patient.get("email", ""),
                        "mobile": patient.get("mobile", ""),
                        "blood_type": patient.get("blood_type", ""),
                        "date_of_birth": patient.get("date_of_birth", ""),
                        "age": patient.get("age", 0),
                        "gender": patient.get("gender", ""),
                        "is_pregnant": patient.get("is_pregnant", False),
                        "is_profile_complete": patient.get("is_profile_complete", False),
                        "status": patient.get("status", "active"),
                        "created_at": patient.get("created_at", ""),
                        "last_login": patient.get("last_login", ""),
                        "address": patient.get("address", ""),
                        "city": patient.get("city", ""),
                        "state": patient.get("state", ""),
                        "pincode": patient.get("pincode", ""),
                        "object_id": str(patient.get("_id", ""))
                    })
                
                return jsonify({
                    "patients": formatted_patients,
                    "total_count": len(formatted_patients),
                    "message": "Patients retrieved successfully"
                }), 200
            else:
                return jsonify({'error': 'Database connection not available'}), 500
            
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def get_patient_details(self, request, patient_id: str) -> tuple:
        """Get detailed patient information for doctor"""
        try:
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            mental_health_collection = self.doctor_model.db.mental_health_collection
            
            # Find patient by patient_id or object_id
            from bson import ObjectId
            patient = patients_collection.find_one({
                "$or": [
                    {"patient_id": patient_id},
                    {"_id": ObjectId(patient_id) if ObjectId.is_valid(patient_id) else None}
                ]
            })
            
            if not patient:
                return jsonify({'error': 'Patient not found'}), 404
            
            # Get patient's mental health logs
            mental_health_logs = list(mental_health_collection.find(
                {"patient_id": patient.get("patient_id")},
                {"_id": 0}
            ).sort("date", -1).limit(10))
            
            # Format patient details
            patient_details = {
                "patient_id": patient.get("patient_id", ""),
                "username": patient.get("username", ""),
                "email": patient.get("email", ""),
                "first_name": patient.get("first_name", ""),
                "last_name": patient.get("last_name", ""),
                "full_name": f"{patient.get('first_name', '')} {patient.get('last_name', '')}".strip() or patient.get('username', 'Unknown'),
                "date_of_birth": patient.get("date_of_birth", ""),
                "blood_type": patient.get("blood_type", ""),
                "mobile": patient.get("mobile", ""),
                "address": patient.get("address", ""),
                "emergency_contact": patient.get("emergency_contact", ""),
                "is_pregnant": patient.get("is_pregnant", False),
                "pregnancy_due_date": patient.get("pregnancy_due_date", ""),
                "is_profile_complete": patient.get("is_profile_complete", False),
                "status": patient.get("status", "active"),
                "created_at": patient.get("created_at", ""),
                "last_login": patient.get("last_login", ""),
                "medical_history": patient.get("medical_history", []),
                "allergies": patient.get("allergies", []),
                "current_medications": patient.get("current_medications", []),
                "mental_health_logs": mental_health_logs,
                "object_id": str(patient.get("_id", ""))
            }
            
            return jsonify({
                "patient": patient_details,
                "message": "Patient details retrieved successfully"
            }), 200
            
        except Exception as e:
            print(f"❌ Error retrieving patient details: {str(e)}")
            return jsonify({'error': f'Server error: {str(e)}'}), 500

    def get_patient_full_details(self, request, patient_id: str) -> tuple:
        """Get complete patient details with all health data in one call"""
        try:
            print(f"🔍 Getting FULL patient details for ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Convert all ObjectIds to strings recursively
            patient = convert_objectid_to_string(patient)
            
            # Get all health data from patient document
            full_details = {
                'success': True,
                'patient_id': patient_id,
                'patient_info': {
                    'full_name': patient.get('full_name', ''),
                    'email': patient.get('email', ''),
                    'mobile': patient.get('mobile', ''),
                    'age': patient.get('age', 0),
                    'blood_type': patient.get('blood_type', ''),
                    'gender': patient.get('gender', ''),
                    'is_pregnant': patient.get('is_pregnant', False),
                    'status': patient.get('status', 'active'),
                    'created_at': patient.get('created_at', ''),
                    'address': patient.get('address', ''),
                    'city': patient.get('city', ''),
                    'state': patient.get('state', ''),
                    'pincode': patient.get('pincode', ''),
                    'date_of_birth': patient.get('date_of_birth', ''),
                    'emergency_contact': patient.get('emergency_contact', {}),
                    'medical_history': patient.get('medical_history', []),
                    'allergies': patient.get('allergies', []),
                    'current_medications': patient.get('current_medications', [])
                },
                'health_data': {
                    'medication_logs': patient.get('medication_logs', []),
                    'symptom_analysis_reports': patient.get('symptom_analysis_reports', []),
                    'food_data': patient.get('food_data', []),
                    'tablet_logs': patient.get('tablet_logs', []),
                    'kick_logs': patient.get('kick_logs', []),
                    'mental_health_logs': patient.get('mental_health_logs', []),
                    'prescription_documents': patient.get('prescription_documents', []),
                    'vital_signs_logs': patient.get('vital_signs_logs', []),
                    'appointments': patient.get('appointments', [])
                },
                'summary': {
                    'total_medications': len(patient.get('medication_logs', [])),
                    'total_symptoms': len(patient.get('symptom_analysis_reports', [])),
                    'total_food_entries': len(patient.get('food_data', [])),
                    'total_tablet_logs': len(patient.get('tablet_logs', [])),
                    'total_kick_logs': len(patient.get('kick_logs', [])),
                    'total_mental_health': len(patient.get('mental_health_logs', [])),
                    'total_prescriptions': len(patient.get('prescription_documents', [])),
                    'total_vital_signs': len(patient.get('vital_signs_logs', [])),
                    'total_appointments': len(patient.get('appointments', []))
                }
            }
            
            # Convert all ObjectIds in the full_details recursively
            full_details = convert_objectid_to_string(full_details)
            
            print(f"✅ Retrieved FULL patient details for: {patient_id}")
            print(f"📊 Summary: {full_details['summary']}")
            
            return jsonify(full_details), 200
            
        except Exception as e:
            print(f"Error getting full patient details: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

    def get_patient_ai_summary(self, request, patient_id: str) -> tuple:
        """Get AI-powered medical summary for a patient"""
        try:
            print(f"🤖 Getting AI summary for patient: {patient_id}")
            
            # First get the full patient details
            full_details_response = self.get_patient_full_details(request, patient_id)
            
            if full_details_response[1] != 200:  # Check status code
                return full_details_response
            
            patient_data = full_details_response[0].get_json()
            
            if not patient_data.get('success'):
                return jsonify({'success': False, 'message': 'Failed to get patient data'}), 400
            
            # Format data for OpenAI
            formatted_data = self._format_patient_data_for_openai(patient_data)
            
            # Get OpenAI summary
            ai_summary = self._get_openai_summary(formatted_data)
            
            if ai_summary:
                return jsonify({
                    'success': True,
                    'patient_id': patient_id,
                    'ai_summary': ai_summary,
                    'patient_name': patient_data.get('patient_info', {}).get('full_name', 'Unknown'),
                    'summary_stats': patient_data.get('summary', {}),
                    'summary_type': 'AI-generated'
                }), 200
            else:
                # Use fallback summary if OpenAI fails
                print('⚠️ OpenAI failed, using fallback summary')
                fallback_summary = self._get_fallback_summary(patient_data)
                return jsonify({
                    'success': True,
                    'patient_id': patient_id,
                    'ai_summary': fallback_summary,
                    'patient_name': patient_data.get('patient_info', {}).get('full_name', 'Unknown'),
                    'summary_stats': patient_data.get('summary', {}),
                    'summary_type': 'fallback-generated',
                    'note': 'OpenAI API temporarily unavailable, using fallback summary'
                }), 200
                
        except Exception as e:
            print(f"Error getting AI summary: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500

    def _format_patient_data_for_openai(self, patient_data):
        """Format patient data for OpenAI analysis"""
        patient_info = patient_data.get('patient_info', {})
        health_data = patient_data.get('health_data', {})
        summary = patient_data.get('summary', {})
        
        formatted_data = f"""
PATIENT SUMMARY REPORT
=====================

PATIENT INFORMATION:
- Name: {patient_info.get('full_name', 'Unknown')}
- Email: {patient_info.get('email', 'N/A')}
- Age: {patient_info.get('age', 'N/A')}
- Blood Type: {patient_info.get('blood_type', 'N/A')}
- Gender: {patient_info.get('gender', 'N/A')}
- Pregnant: {patient_info.get('is_pregnant', False)}
- Status: {patient_info.get('status', 'N/A')}
- Date of Birth: {patient_info.get('date_of_birth', 'N/A')}
- Mobile: {patient_info.get('mobile', 'N/A')}
- Address: {patient_info.get('address', 'N/A')}
- Emergency Contact: {patient_info.get('emergency_contact', {})}

HEALTH DATA SUMMARY:
- Total Appointments: {summary.get('total_appointments', 0)}
- Food & Nutrition Entries: {summary.get('total_food_entries', 0)}
- Symptom Analysis Reports: {summary.get('total_symptoms', 0)}
- Mental Health Logs: {summary.get('total_mental_health', 0)}
- Medication History: {summary.get('total_medications', 0)}
- Kick Count Logs: {summary.get('total_kick_logs', 0)}
- Prescription Documents: {summary.get('total_prescriptions', 0)}
- Vital Signs Logs: {summary.get('total_vital_signs', 0)}

DETAILED HEALTH INFORMATION:
"""

        # Add detailed health data
        if health_data.get('food_data'):
            formatted_data += "\nFOOD & NUTRITION LOGS:\n"
            for i, food in enumerate(health_data['food_data'][:5]):  # Limit to 5 entries
                formatted_data += f"- {food.get('food_input', 'N/A')} ({food.get('meal_type', 'N/A')})\n"
        
        if health_data.get('symptom_analysis_reports'):
            formatted_data += "\nSYMPTOM ANALYSIS REPORTS:\n"
            for i, symptom in enumerate(health_data['symptom_analysis_reports'][:5]):  # Limit to 5 entries
                formatted_data += f"- {symptom.get('symptom_text', 'N/A')} (Severity: {symptom.get('severity', 'N/A')})\n"
        
        if health_data.get('mental_health_logs'):
            formatted_data += "\nMENTAL HEALTH LOGS:\n"
            for i, mood in enumerate(health_data['mental_health_logs'][:5]):  # Limit to 5 entries
                formatted_data += f"- Mood: {mood.get('mood', 'N/A')} (Date: {mood.get('date', 'N/A')})\n"
        
        if health_data.get('appointments'):
            formatted_data += "\nAPPOINTMENTS:\n"
            for i, appointment in enumerate(health_data['appointments'][:5]):  # Limit to 5 entries
                formatted_data += f"- {appointment.get('appointment_type', 'N/A')} on {appointment.get('appointment_date', 'N/A')} at {appointment.get('appointment_time', 'N/A')}\n"
        
        return formatted_data

    def _get_openai_summary(self, patient_data_text):
        """Get OpenAI summarization of patient data"""
        try:
            import os
            from openai import OpenAI
            
            # Get OpenAI API key from environment variables
            api_key = os.getenv('OPENAI_API_KEY')
            
            if not api_key:
                print('❌ OpenAI API key not found in environment variables')
                print('💡 For local development: Add OPENAI_API_KEY to .env file')
                print('💡 For Render deployment: Set OPENAI_API_KEY in Render Dashboard > Environment')
                return None
            
            if not api_key.startswith('sk-'):
                print('❌ Invalid OpenAI API key format (should start with sk-)')
                print(f'   Current key format: {api_key[:10]}...{api_key[-4:] if len(api_key) > 14 else api_key}')
                return None
            
            print(f'✅ OpenAI API key found: {api_key[:10]}...{api_key[-4:]}')
            
            # Simple OpenAI client initialization for version 1.3.0
            try:
                import openai
                openai.api_key = api_key
                print('✅ OpenAI client initialized with simple method')
            except Exception as client_error:
                print(f'❌ Failed to initialize OpenAI client: {client_error}')
                print(f'   Error type: {type(client_error).__name__}')
                return None
            
            print('🤖 Sending data to OpenAI for summarization...')
            
            # Create the prompt for OpenAI
            prompt = f"""
Please analyze the following patient data and provide a comprehensive medical summary. Focus on:

1. Patient Overview (demographics, pregnancy status, general health indicators)
2. Health Data Analysis (patterns in symptoms, nutrition, mental health)
3. Key Concerns or Recommendations
4. Overall Health Assessment
5. Priority Areas for Medical Attention

Patient Data:
{patient_data_text}

Please provide a clear, professional medical summary suitable for a doctor's review.
"""
            
            # Call OpenAI API with simple method
            try:
                print('📡 Making OpenAI API request...')
                response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a medical AI assistant that analyzes patient data and provides professional medical summaries for doctors."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=1000,
                temperature=0.3
            )
                print('✅ OpenAI API call successful')
            
                print(f'✅ OpenAI API response received: {response.usage.total_tokens} tokens used')
                print(f'✅ Model used: {response.model}')
                return response.choices[0].message.content
            
            except Exception as openai_error:
                print(f'❌ OpenAI API call failed: {openai_error}')
                print(f'   Error type: {type(openai_error).__name__}')
                print(f'   Error details: {str(openai_error)}')
                
                # Handle specific OpenAI errors
                error_str = str(openai_error).lower()
                if "insufficient_quota" in error_str:
                    print('💡 OpenAI API quota exceeded - check your billing')
                elif "invalid_api_key" in error_str or "authentication" in error_str:
                    print('💡 Invalid API key - verify your OpenAI API key')
                elif "rate_limit" in error_str:
                    print('💡 Rate limit exceeded - try again later')
                elif "timeout" in error_str:
                    print('💡 Request timeout - OpenAI API may be slow')
                elif "connection" in error_str:
                    print('💡 Connection error - check network connectivity')
                else:
                    print(f'💡 Unknown OpenAI error: {error_str}')
                
                return None
            
        except ImportError as import_error:
            print(f'❌ OpenAI library not installed: {import_error}')
            print('💡 Install with: pip install openai')
            return None
        except Exception as e:
            print(f'❌ Unexpected error with OpenAI API: {e}')
            print(f'   Error type: {type(e).__name__}')
            print(f'   Error details: {str(e)}')
            return None
    
    def _get_fallback_summary(self, patient_data):
        """Generate a simple summary without AI"""
        try:
            patient_info = patient_data.get('patient_info', {})
            summary_stats = patient_data.get('summary', {})
            
            # Extract key information
            name = patient_info.get('full_name', 'Unknown Patient')
            age = patient_info.get('age', 'N/A')
            gender = patient_info.get('gender', 'N/A')
            blood_type = patient_info.get('blood_type', 'N/A')
            is_pregnant = patient_info.get('is_pregnant', False)
            
            # Count health data
            total_medications = summary_stats.get('total_medications', 0)
            total_symptoms = summary_stats.get('total_symptoms', 0)
            total_food_entries = summary_stats.get('total_food_entries', 0)
            total_mental_health = summary_stats.get('total_mental_health', 0)
            total_appointments = summary_stats.get('total_appointments', 0)
            
            # Generate summary
            summary = f"""PATIENT HEALTH SUMMARY (Fallback Mode)
=====================================

PATIENT OVERVIEW:
- Name: {name}
- Age: {age}
- Gender: {gender}
- Blood Type: {blood_type}
- Pregnancy Status: {'Pregnant' if is_pregnant else 'Not Pregnant'}

HEALTH DATA SUMMARY:
- Total Medications: {total_medications}
- Symptom Reports: {total_symptoms}
- Food/Nutrition Entries: {total_food_entries}
- Mental Health Logs: {total_mental_health}
- Appointments: {total_appointments}

HEALTH ASSESSMENT:
Based on the available data, this patient has {'active' if (total_medications + total_symptoms + total_food_entries + total_mental_health) > 0 else 'limited'} health monitoring activity.

RECOMMENDATIONS:
1. Continue regular health monitoring through the platform
2. {'Maintain medication compliance' if total_medications > 0 else 'Consider medication management if needed'}
3. {'Monitor symptom patterns' if total_symptoms > 0 else 'Track symptoms for early detection'}
4. {'Continue nutrition tracking' if total_food_entries > 0 else 'Consider adding nutrition logging'}
5. {'Maintain mental health awareness' if total_mental_health > 0 else 'Consider mental health monitoring'}

PRIORITY AREAS:
- Regular medical check-ups
- Medication adherence {'(active monitoring needed)' if total_medications > 0 else '(no current medications)'}
- Symptom tracking {'(ongoing)' if total_symptoms > 0 else '(no recent symptoms)'}
- Overall health maintenance

NOTE: This is a fallback summary generated without AI assistance. 
For more detailed analysis, the OpenAI integration needs to be restored."""
            
            return summary.strip()
            
        except Exception as e:
            print(f'❌ Error generating fallback summary: {e}')
            return "Error generating summary. Please try again later."
    
    def get_appointments(self, request) -> tuple:
        """Get appointments for doctor"""
        try:
            # For doctor-only app, we don't need to validate doctor_id
            # Get appointments from the database using the working logic from app_simple.py
            if hasattr(self.doctor_model, 'db') and hasattr(self.doctor_model.db, 'patients_collection'):
                patients_collection = self.doctor_model.db.patients_collection
                
                # Get query parameters for filtering
                patient_id = request.args.get('patient_id')
                date = request.args.get('date')
                status = request.args.get('status', 'active')
                
                print(f"🔍 Getting appointments - patient_id: {patient_id}, date: {date}, status: {status}")
                
                all_appointments = []
                
                if patient_id:
                    # Get appointments for specific patient
                    patient = patients_collection.find_one({"patient_id": patient_id})
                    if patient and 'appointments' in patient:
                        patient_name = f"{patient.get('first_name', '')} {patient.get('last_name', '')}".strip() or patient.get('username', 'Unknown')
                        for appointment in patient['appointments']:
                            appointment_data = appointment.copy()
                            appointment_data['patient_id'] = patient_id
                            appointment_data['patient_name'] = patient_name
                            
                            # Filter by date if provided
                            if not date or appointment.get('appointment_date') == date:
                                all_appointments.append(appointment_data)
                else:
                    # Get appointments from all patients that have appointments
                    patients = patients_collection.find({"appointments": {"$exists": True, "$ne": []}})
                    
                    for patient in patients:
                        patient_name = f"{patient.get('first_name', '')} {patient.get('last_name', '')}".strip() or patient.get('username', 'Unknown')
                        
                        for appointment in patient.get('appointments', []):
                            appointment_data = appointment.copy()
                            appointment_data['patient_id'] = patient['patient_id']
                            appointment_data['patient_name'] = patient_name
                            
                            # Filter by date if provided
                            if not date or appointment.get('appointment_date') == date:
                                all_appointments.append(appointment_data)
                
                # Sort by appointment date
                all_appointments.sort(key=lambda x: x.get('appointment_date', ''))
                
                print(f"✅ Found {len(all_appointments)} appointments")
                
                return jsonify({
                    "appointments": all_appointments,
                    "total_count": len(all_appointments),
                    "message": "Appointments retrieved successfully"
                }), 200
            else:
                return jsonify({'error': 'Database connection not available'}), 500
            
        except Exception as e:
            print(f"❌ Error retrieving appointments: {str(e)}")
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def create_appointment(self, request) -> tuple:
        """Create a new appointment - saved in patient document"""
        try:
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            data = request.get_json()
            print(f"🔍 Creating appointment - data: {data}")
            
            # Validate required fields
            required_fields = ['patient_id', 'appointment_date', 'appointment_time']
            for field in required_fields:
                if not data.get(field):
                    return jsonify({'error': f'{field} is required'}), 400
            
            # Check if patient exists
            patient = patients_collection.find_one({"patient_id": data["patient_id"]})
            if not patient:
                return jsonify({'error': 'Patient not found'}), 404
            
            print(f"✅ Patient found: {patient.get('first_name', '')} {patient.get('last_name', '')}")
            
            # Generate unique appointment ID
            from bson import ObjectId
            appointment_id = str(ObjectId())
            
            # Create appointment object
            appointment = {
                "appointment_id": appointment_id,
                "appointment_date": data["appointment_date"],
                "appointment_time": data["appointment_time"],
                "appointment_type": data.get("appointment_type", "General"),
                "appointment_status": "scheduled",
                "notes": data.get("notes", ""),
                "doctor_id": data.get("doctor_id", ""),
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat(),
                "status": "active"
            }
            
            print(f"💾 Saving appointment to patient {data['patient_id']}: {appointment}")
            
            # Add appointment to patient's appointments array
            result = patients_collection.update_one(
                {"patient_id": data["patient_id"]},
                {"$push": {"appointments": appointment}}
            )
            
            if result.modified_count > 0:
                print(f"✅ Appointment saved successfully!")
                return jsonify({
                    "appointment_id": appointment_id,
                    "message": "Appointment created successfully"
                }), 201
            else:
                return jsonify({'error': 'Failed to save appointment'}), 500
            
        except Exception as e:
            print(f"❌ Error creating appointment: {str(e)}")
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def get_appointment_by_id(self, request, appointment_id: str) -> tuple:
        """Get a single appointment by ID"""
        try:
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            print(f"🔍 Getting appointment {appointment_id}")
            
            # Find the patient with this appointment
            patient = patients_collection.find_one({
                "appointments.appointment_id": appointment_id
            })
            
            if not patient:
                return jsonify({'error': 'Appointment not found'}), 404
            
            # Find the specific appointment in the appointments array
            appointment = None
            for apt in patient.get('appointments', []):
                if apt.get('appointment_id') == appointment_id:
                    appointment = apt
                    # Add patient name to the appointment
                    patient_name = f"{patient.get('first_name', '')} {patient.get('last_name', '')}".strip() or patient.get('username', 'Unknown')
                    appointment['patient_name'] = patient_name
                    appointment['patient_id'] = patient.get('patient_id')
                    break
            
            if not appointment:
                return jsonify({'error': 'Appointment not found'}), 404
            
            print(f"✅ Found appointment: {appointment.get('appointment_date')} at {appointment.get('appointment_time')}")
            
            return jsonify({
                'success': True,
                'appointment': appointment
            }), 200
            
        except Exception as e:
            print(f"❌ Error getting appointment: {str(e)}")
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def update_appointment(self, request, appointment_id: str) -> tuple:
        """Update an appointment"""
        try:
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            data = request.get_json()
            
            print(f"🔍 Updating appointment {appointment_id} with data: {data}")
            
            # Find the patient with this appointment
            patient = patients_collection.find_one({
                "appointments.appointment_id": appointment_id
            })
            
            if not patient:
                return jsonify({'error': 'Appointment not found'}), 404
            
            # Build update fields
            update_fields = {}
            if 'appointment_date' in data:
                update_fields['appointments.$.appointment_date'] = data['appointment_date']
            if 'appointment_time' in data:
                update_fields['appointments.$.appointment_time'] = data['appointment_time']
            if 'appointment_type' in data:
                update_fields['appointments.$.appointment_type'] = data['appointment_type']
            if 'appointment_mode' in data:
                update_fields['appointments.$.appointment_mode'] = data['appointment_mode']
            if 'video_link' in data:
                update_fields['appointments.$.video_link'] = data['video_link']
            if 'appointment_status' in data:
                update_fields['appointments.$.appointment_status'] = data['appointment_status']
            if 'notes' in data:
                update_fields['appointments.$.notes'] = data['notes']
            
            update_fields['appointments.$.updated_at'] = datetime.now().isoformat()
            
            # Update the appointment
            result = patients_collection.update_one(
                {"appointments.appointment_id": appointment_id},
                {"$set": update_fields}
            )
            
            if result.modified_count > 0:
                print(f"✅ Appointment {appointment_id} updated successfully")
                return jsonify({
                    'success': True,
                    'message': 'Appointment updated successfully',
                    'appointment_id': appointment_id
                }), 200
            else:
                return jsonify({'error': 'No changes made or appointment not found'}), 400
                
        except Exception as e:
            print(f"❌ Error updating appointment: {str(e)}")
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def delete_appointment(self, request, appointment_id: str) -> tuple:
        """Delete an appointment"""
        try:
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            print(f"🔍 Deleting appointment {appointment_id}")
            
            # Find the patient with this appointment
            patient = patients_collection.find_one({
                "appointments.appointment_id": appointment_id
            })
            
            if not patient:
                return jsonify({'error': 'Appointment not found'}), 404
            
            # Remove the appointment from the array
            result = patients_collection.update_one(
                {"appointments.appointment_id": appointment_id},
                {"$pull": {"appointments": {"appointment_id": appointment_id}}}
            )
            
            if result.modified_count > 0:
                print(f"✅ Appointment {appointment_id} deleted successfully")
                return jsonify({
                    'success': True,
                    'message': 'Appointment deleted successfully',
                    'appointment_id': appointment_id
                }), 200
            else:
                return jsonify({'error': 'Failed to delete appointment'}), 500
                
        except Exception as e:
            print(f"❌ Error deleting appointment: {str(e)}")
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def get_dashboard_stats(self, request) -> tuple:
        """Get dashboard statistics for doctor"""
        try:
            # For doctor-only app, we don't need to validate doctor_id
            # Get real statistics from the database
            if hasattr(self.doctor_model, 'db') and hasattr(self.doctor_model.db, 'patients_collection'):
                patients_collection = self.doctor_model.db.patients_collection
                
                # Get real patient count
                total_patients = patients_collection.count_documents({"status": {"$ne": "deleted"}})
                
                # Get appointments count
                patients_with_appointments = patients_collection.find({"appointments": {"$exists": True, "$ne": []}})
                total_appointments = 0
                for patient in patients_with_appointments:
                    total_appointments += len(patient.get('appointments', []))
                
                # Sample dashboard statistics (you can enhance this with real data)
                stats = {
                    'total_patients': total_patients,
                    'total_appointments': total_appointments,
                    'today_appointments': 0,  # You can implement date filtering
                    'pending_appointments': 0,  # You can implement status filtering
                    'completed_appointments': 0,  # You can implement status filtering
                    'revenue_today': 0.00,
                    'revenue_month': 0.00
                }
                
                return jsonify({
                    'success': True,
                    'stats': stats
                }), 200
            else:
                return jsonify({'error': 'Database connection not available'}), 500
            
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500
    
    def get_medication_history(self, request, patient_id: str) -> tuple:
        """Get medication history for a patient"""
        try:
            print(f"🔍 Getting medication history for patient ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Get medication logs from patient document
            medication_logs = patient.get('medication_logs', [])
            
            # Convert ObjectId to string for JSON serialization
            for log in medication_logs:
                if '_id' in log:
                    log['_id'] = str(log['_id'])
            
            # Sort by newest first (using created_at or timestamp)
            medication_logs.sort(key=lambda x: x.get('created_at', x.get('timestamp', '')), reverse=True)
            
            print(f"✅ Retrieved {len(medication_logs)} medication logs for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'patientId': patient_id,
                'medication_logs': medication_logs,
                'totalEntries': len(medication_logs)
            }), 200
            
        except Exception as e:
            print(f"Error getting medication history: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
    
    def get_symptom_analysis_reports(self, request, patient_id: str) -> tuple:
        """Get only the AI analysis reports for a patient"""
        try:
            print(f"🔍 Getting analysis reports for patient ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Get analysis reports from patient document
            analysis_reports = patient.get('symptom_analysis_reports', [])
            
            # Sort by timestamp (newest first)
            analysis_reports.sort(key=lambda x: x.get('timestamp', x.get('created_at', '')), reverse=True)
            
            print(f"✅ Retrieved {len(analysis_reports)} analysis reports for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'patientId': patient_id,
                'analysis_reports': analysis_reports,
                'totalReports': len(analysis_reports)
            }), 200
            
        except Exception as e:
            print(f"Error getting analysis reports: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
    
    def get_food_entries(self, request, patient_id: str) -> tuple:
        """Get food entries from patient's food_data array"""
        try:
            print(f"🍽️ Getting food entries for user ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({
                    'success': False,
                    'message': f'Patient not found with ID: {patient_id}'
                }), 404
            
            # Get food_data array from patient document
            food_data = patient.get('food_data', [])
            
            # Sort by timestamp (most recent first)
            food_data.sort(key=lambda x: x.get('timestamp', x.get('created_at', '')), reverse=True)
            
            print(f"✅ Retrieved {len(food_data)} food entries for user: {patient_id}")
            
            return jsonify({
                'success': True,
                'user_id': patient_id,
                'food_data': food_data,
                'total_entries': len(food_data)
            }), 200
            
        except Exception as e:
            print(f"❌ Error getting food entries: {e}")
            return jsonify({
                'success': False,
                'message': f'Error: {str(e)}'
            }), 500
    
    def get_tablet_tracking_history(self, request, patient_id: str) -> tuple:
        """Get tablet tracking history for a patient"""
        try:
            print(f"🔍 Getting tablet tracking history for patient ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Get tablet tracking logs from patient document
            tablet_logs = patient.get('tablet_tracking_logs', [])
            
            # Sort by newest first
            tablet_logs.sort(key=lambda x: x.get('timestamp', x.get('created_at', '')), reverse=True)
            
            print(f"✅ Retrieved {len(tablet_logs)} tablet tracking logs for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'patientId': patient_id,
                'tablet_logs': tablet_logs,
                'totalEntries': len(tablet_logs)
            }), 200
            
        except Exception as e:
            print(f"Error getting tablet tracking history: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
    
    def get_patient_profile(self, request, patient_id: str) -> tuple:
        """Get patient profile information"""
        try:
            print(f"🔍 Getting patient profile for ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Format patient profile
            profile = {
                'patient_id': patient.get('patient_id', ''),
                'username': patient.get('username', ''),
                'email': patient.get('email', ''),
                'first_name': patient.get('first_name', ''),
                'last_name': patient.get('last_name', ''),
                'full_name': f"{patient.get('first_name', '')} {patient.get('last_name', '')}".strip() or patient.get('username', 'Unknown'),
                'date_of_birth': patient.get('date_of_birth', ''),
                'blood_type': patient.get('blood_type', ''),
                'mobile': patient.get('mobile', ''),
                'address': patient.get('address', ''),
                'is_pregnant': patient.get('is_pregnant', False),
                'pregnancy_due_date': patient.get('pregnancy_due_date', ''),
                'is_profile_complete': patient.get('is_profile_complete', False),
                'status': patient.get('status', 'active'),
                'created_at': patient.get('created_at', ''),
                'last_login': patient.get('last_login', ''),
                'object_id': str(patient.get('_id', ''))
            }
            
            print(f"✅ Retrieved profile for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'patientId': patient_id,
                'profile': profile
            }), 200
            
        except Exception as e:
            print(f"Error getting patient profile: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
    
    def get_kick_count_history(self, request, patient_id: str) -> tuple:
        """Get kick count history for a patient"""
        try:
            print(f"🔍 Getting kick count history for patient ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Get kick count logs from patient document
            kick_logs = patient.get('kick_count_logs', [])
            
            # Sort by newest first
            kick_logs.sort(key=lambda x: x.get('timestamp', x.get('created_at', '')), reverse=True)
            
            print(f"✅ Retrieved {len(kick_logs)} kick count logs for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'patientId': patient_id,
                'kick_logs': kick_logs,
                'totalEntries': len(kick_logs)
            }), 200
            
        except Exception as e:
            print(f"Error getting kick count history: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
    
    def get_mental_health_history(self, request, patient_id: str) -> tuple:
        """Get mental health history for a patient"""
        try:
            print(f"🔍 Getting mental health history for patient ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Get mental health logs from patient document
            mental_health_logs = patient.get('mental_health_logs', [])
            
            # Convert ObjectId to string for JSON serialization
            for log in mental_health_logs:
                if '_id' in log:
                    log['_id'] = str(log['_id'])
            
            # Sort by newest first
            mental_health_logs.sort(key=lambda x: x.get('date', x.get('created_at', '')), reverse=True)
            
            print(f"✅ Retrieved {len(mental_health_logs)} mental health logs for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'data': {
                    'patient_id': patient_id,
                    'mood_history': mental_health_logs,
                    'assessment_history': [],
                    'total_mood_entries': len(mental_health_logs),
                    'total_assessment_entries': 0
                }
            }), 200
            
        except Exception as e:
            print(f"❌ Get mental health history error: {e}")
            return jsonify({
                'success': False,
                'message': f'Internal server error: {str(e)}'
            }), 500
    
    def get_prescription_documents(self, request, patient_id: str) -> tuple:
        """Get prescription documents for a patient"""
        try:
            print(f"🔍 Getting prescription documents for patient ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Get prescription documents from patient document
            prescription_documents = patient.get('prescription_documents', [])
            
            # Sort by newest first
            prescription_documents.sort(key=lambda x: x.get('created_at', x.get('date', '')), reverse=True)
            
            print(f"✅ Retrieved {len(prescription_documents)} prescription documents for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'patientId': patient_id,
                'prescription_documents': prescription_documents,
                'totalDocuments': len(prescription_documents)
            }), 200
            
        except Exception as e:
            print(f"Error getting prescription documents: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
    
    def get_vital_signs_history(self, request, patient_id: str) -> tuple:
        """Get vital signs history for a patient"""
        try:
            print(f"🔍 Getting vital signs history for patient ID: {patient_id}")
            
            if not hasattr(self.doctor_model, 'db') or not hasattr(self.doctor_model.db, 'patients_collection'):
                return jsonify({'error': 'Database connection not available'}), 500
            
            patients_collection = self.doctor_model.db.patients_collection
            
            # Find patient by Patient ID
            patient = patients_collection.find_one({"patient_id": patient_id})
            if not patient:
                return jsonify({'success': False, 'message': f'Patient not found with ID: {patient_id}'}), 404
            
            # Get vital signs logs from patient document
            vital_signs_logs = patient.get('vital_signs_logs', [])
            
            # Sort by newest first
            vital_signs_logs.sort(key=lambda x: x.get('created_at', x.get('date', '')), reverse=True)
            
            print(f"✅ Retrieved {len(vital_signs_logs)} vital signs logs for patient: {patient_id}")
            
            return jsonify({
                'success': True,
                'patientId': patient_id,
                'vital_signs_logs': vital_signs_logs,
                'totalEntries': len(vital_signs_logs)
            }), 200
            
        except Exception as e:
            print(f"Error getting vital signs history: {e}")
            return jsonify({'success': False, 'message': f'Error: {str(e)}'}), 500
    
    def get_profile_fields(self, request) -> tuple:
        """Get doctor profile fields - returns available fields for profile completion"""
        try:
            # Return the list of fields that can be updated in doctor profile
            profile_fields = {
                'personal_info': {
                    'first_name': {'type': 'string', 'required': True, 'description': 'Doctor first name'},
                    'last_name': {'type': 'string', 'required': True, 'description': 'Doctor last name'},
                    'email': {'type': 'email', 'required': True, 'description': 'Doctor email address'},
                    'mobile': {'type': 'string', 'required': True, 'description': 'Doctor mobile number'}
                },
                'professional_info': {
                    'specialization': {'type': 'string', 'required': True, 'description': 'Medical specialization'},
                    'license_number': {'type': 'string', 'required': True, 'description': 'Medical license number'},
                    'experience_years': {'type': 'number', 'required': True, 'description': 'Years of experience'},
                    'qualifications': {'type': 'array', 'required': False, 'description': 'List of qualifications'}
                },
                'practice_info': {
                    'hospital_name': {'type': 'string', 'required': False, 'description': 'Hospital or clinic name'},
                    'consultation_fee': {'type': 'number', 'required': False, 'description': 'Consultation fee'},
                    'available_timings': {'type': 'object', 'required': False, 'description': 'Available consultation timings'},
                    'languages': {'type': 'array', 'required': False, 'description': 'Languages spoken'}
                },
                'address_info': {
                    'address': {'type': 'string', 'required': False, 'description': 'Practice address'},
                    'city': {'type': 'string', 'required': False, 'description': 'City'},
                    'state': {'type': 'string', 'required': False, 'description': 'State'},
                    'pincode': {'type': 'string', 'required': False, 'description': 'Pincode'}
                }
            }
            
            return jsonify({
                'success': True,
                'profile_fields': profile_fields,
                'message': 'Available doctor profile fields'
            }), 200
            
        except Exception as e:
            return jsonify({'error': f'Server error: {str(e)}'}), 500