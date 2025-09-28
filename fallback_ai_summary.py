"""
Fallback AI Summary Solution
Provides a simple text-based summary when OpenAI API is unavailable
"""

def generate_fallback_summary(patient_data):
    """Generate a simple summary without AI"""
    
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
    summary = f"""
PATIENT HEALTH SUMMARY (Fallback Mode)
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
For more detailed analysis, the OpenAI integration needs to be restored.
"""
    
    return summary.strip()

def test_fallback_summary():
    """Test the fallback summary function"""
    sample_data = {
        'patient_info': {
            'full_name': 'John Doe',
            'age': 28,
            'gender': 'Male',
            'blood_type': 'O+',
            'is_pregnant': False
        },
        'summary': {
            'total_medications': 1,
            'total_symptoms': 1,
            'total_food_entries': 3,
            'total_mental_health': 1,
            'total_appointments': 1
        }
    }
    
    summary = generate_fallback_summary(sample_data)
    print("Fallback Summary Test:")
    print("=" * 50)
    print(summary)
    return summary

if __name__ == "__main__":
    test_fallback_summary()
