# Patient AI Summary Endpoints Documentation

This document provides comprehensive input/output documentation for the Patient AI Summary endpoints, including setup requirements and usage examples.

## 📋 Overview

The Patient AI Summary system uses OpenAI's GPT-3.5-turbo model to analyze comprehensive patient data and generate professional medical summaries for doctors. The system aggregates data from multiple sources including symptoms, medications, nutrition, mental health logs, and appointments.

## 🔧 Prerequisites

### OpenAI API Key Setup
Before using the AI summary endpoints, you must configure the OpenAI API key:

1. **Get OpenAI API Key:**
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create a new API key
   - Copy the key (starts with `sk-`)

2. **Configure Environment Variable:**
   ```bash
   # Add to your .env file or environment variables
   OPENAI_API_KEY=sk-your-openai-api-key-here
   ```

3. **Restart the Backend Server:**
   ```bash
   python app_mvc.py
   ```

## 🚀 API Endpoints

### 1. Get Patient AI Summary

**Endpoint:** `GET /doctor/patient/{patient_id}/ai-summary`

**Purpose:** Generate an AI-powered medical summary for a specific patient

**Authentication:** Required (Bearer Token)

---

## 📥 Input Parameters

### Path Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `patient_id` | String | Yes | Unique patient identifier (e.g., "PAT1758712159E182A3") |

### Headers
| Header | Type | Required | Description |
|--------|------|----------|-------------|
| `Authorization` | String | Yes | Bearer token for authentication |
| `Content-Type` | String | No | application/json (for requests with body) |

### Request Body
**None** - This is a GET request that retrieves all patient data automatically.

---

## 📤 Output Response

### Success Response (200 OK)

```json
{
  "success": true,
  "patient_id": "PAT1758712159E182A3",
  "patient_name": "John Doe",
  "ai_summary": "COMPREHENSIVE MEDICAL SUMMARY\n\nPATIENT OVERVIEW:\nJohn Doe is a 28-year-old male patient with a comprehensive health profile. Based on the available data, the patient shows active engagement with health monitoring through multiple channels.\n\nHEALTH DATA ANALYSIS:\n- The patient has logged 3 food entries, indicating good nutrition tracking habits\n- 1 symptom analysis report suggests proactive health monitoring\n- 1 mental health log entry shows attention to mental well-being\n- 1 medication entry indicates current medication management\n- 1 appointment scheduled demonstrates regular medical care\n\nKEY CONCERNS & RECOMMENDATIONS:\n1. Continue regular health monitoring through the platform\n2. Maintain consistent medication adherence as indicated by the single medication entry\n3. Consider expanding mental health logging for better trend analysis\n4. Regular follow-up appointments are recommended\n\nOVERALL HEALTH ASSESSMENT:\nThe patient demonstrates good health awareness and proactive monitoring. The data suggests a well-engaged patient with multiple health tracking activities.\n\nPRIORITY AREAS FOR MEDICAL ATTENTION:\n- Monitor medication compliance and effectiveness\n- Review symptom patterns for any emerging health concerns\n- Assess mental health trends for overall well-being\n- Ensure regular medical check-ups continue",
  "summary_stats": {
    "total_medications": 1,
    "total_symptoms": 1,
    "total_food_entries": 3,
    "total_tablet_logs": 0,
    "total_kick_logs": 0,
    "total_mental_health": 1,
    "total_prescriptions": 0,
    "total_vital_signs": 0,
    "total_appointments": 1
  }
}
```

### Error Responses

#### 400 Bad Request - Invalid Patient Data
```json
{
  "success": false,
  "message": "Failed to get patient data"
}
```

#### 401 Unauthorized - Missing Authentication
```json
{
  "error": "Unauthorized access"
}
```

#### 404 Not Found - Patient Not Found
```json
{
  "success": false,
  "message": "Patient not found"
}
```

#### 500 Internal Server Error - OpenAI API Issues
```json
{
  "success": false,
  "message": "Failed to generate AI summary"
}
```

#### 500 Internal Server Error - Missing API Key
```json
{
  "success": false,
  "message": "OpenAI API key not configured"
}
```

---

## 🔍 Data Sources Analyzed

The AI summary endpoint automatically collects and analyzes data from the following sources:

### Patient Information
- Demographics (name, age, gender, blood type)
- Contact information
- Pregnancy status (if applicable)
- Emergency contacts

### Health Data Categories
1. **Appointments** - Medical appointments and consultations
2. **Food & Nutrition** - Dietary logs and nutritional tracking
3. **Symptoms** - Symptom analysis reports and health concerns
4. **Mental Health** - Mental health logs and assessments
5. **Medications** - Medication history and compliance
6. **Kick Counts** - Fetal movement tracking (for pregnant patients)
7. **Prescriptions** - Prescription documents and medications
8. **Vital Signs** - Blood pressure, heart rate, temperature, etc.
9. **Tablet Logs** - Medication adherence tracking

### Summary Statistics
- Total counts for each health data category
- Recent activity patterns
- Data completeness indicators

---

## 🤖 AI Analysis Process

### 1. Data Collection
The system automatically retrieves comprehensive patient data from the database, including:
- Patient profile information
- All health data entries across categories
- Summary statistics and counts

### 2. Data Formatting
Patient data is formatted into a structured report for AI analysis:
```
PATIENT SUMMARY REPORT
=====================

PATIENT INFORMATION:
- Name: John Doe
- Email: john.doe@example.com
- Age: 28
- Blood Type: O+
- Gender: Male
- Pregnant: No
- Status: Active
- Date of Birth: 1995-03-15
- Mobile: +1234567890
- Address: 123 Main St, City, State
- Emergency Contact: Jane Doe (+0987654321)

HEALTH DATA SUMMARY:
- Total Appointments: 1
- Food & Nutrition Entries: 3
- Symptom Analysis Reports: 1
- Mental Health Logs: 1
- Medication History: 1
- Kick Count Logs: 0
- Prescription Documents: 0
- Vital Signs Logs: 0

DETAILED HEALTH INFORMATION:
[Detailed data from each category...]
```

### 3. AI Processing
The formatted data is sent to OpenAI GPT-3.5-turbo with a medical analysis prompt:

**AI Prompt Structure:**
```
Please analyze the following patient data and provide a comprehensive medical summary. Focus on:

1. Patient Overview (demographics, pregnancy status, general health indicators)
2. Health Data Analysis (patterns in symptoms, nutrition, mental health)
3. Key Concerns or Recommendations
4. Overall Health Assessment
5. Priority Areas for Medical Attention

Patient Data:
[Formatted patient data]

Please provide a clear, professional medical summary suitable for a doctor's review.
```

### 4. Response Generation
The AI generates a structured medical summary covering:
- **Patient Overview** - Demographics and general status
- **Health Data Analysis** - Patterns and trends in health data
- **Key Concerns** - Important medical observations
- **Recommendations** - Suggested actions or follow-ups
- **Priority Areas** - Areas requiring medical attention

---

## 📊 Response Fields Explained

### Main Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Indicates if the request was successful |
| `patient_id` | String | The patient identifier used in the request |
| `patient_name` | String | Full name of the patient |
| `ai_summary` | String | AI-generated medical summary text |
| `summary_stats` | Object | Statistical summary of patient data |

### Summary Stats Object

| Field | Type | Description |
|-------|------|-------------|
| `total_appointments` | Integer | Number of medical appointments |
| `total_food_entries` | Integer | Number of nutrition logs |
| `total_symptoms` | Integer | Number of symptom reports |
| `total_mental_health` | Integer | Number of mental health logs |
| `total_medications` | Integer | Number of medication entries |
| `total_kick_logs` | Integer | Number of fetal movement logs |
| `total_prescriptions` | Integer | Number of prescription documents |
| `total_vital_signs` | Integer | Number of vital signs entries |
| `total_tablet_logs` | Integer | Number of medication adherence logs |

---

## 🔧 Configuration

### OpenAI Model Configuration
- **Model:** `gpt-3.5-turbo`
- **Max Tokens:** 1000
- **Temperature:** 0.3 (for consistent, professional output)
- **System Role:** Medical AI assistant

### Rate Limits
- OpenAI API rate limits apply
- Consider implementing caching for frequently accessed summaries
- Monitor API usage and costs

---

## 🧪 Testing Examples

### cURL Example
```bash
curl -X GET "http://localhost:5000/doctor/patient/PAT1758712159E182A3/ai-summary" \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json"
```

### JavaScript/Fetch Example
```javascript
const response = await fetch('http://localhost:5000/doctor/patient/PAT1758712159E182A3/ai-summary', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer YOUR_AUTH_TOKEN',
    'Content-Type': 'application/json'
  }
});

const data = await response.json();
console.log(data.ai_summary);
```

### Python Example
```python
import requests

url = "http://localhost:5000/doctor/patient/PAT1758712159E182A3/ai-summary"
headers = {
    "Authorization": "Bearer YOUR_AUTH_TOKEN",
    "Content-Type": "application/json"
}

response = requests.get(url, headers=headers)
data = response.json()

if data['success']:
    print("AI Summary:", data['ai_summary'])
    print("Patient Stats:", data['summary_stats'])
else:
    print("Error:", data['message'])
```

---

## 🚨 Troubleshooting

### Common Issues

#### 1. "OpenAI API key not found"
**Solution:** Add `OPENAI_API_KEY=your_key_here` to your `.env` file and restart the server.

#### 2. "Failed to generate AI summary"
**Possible Causes:**
- OpenAI API key invalid or expired
- OpenAI API quota exceeded
- Network connectivity issues
- Invalid patient data

#### 3. "Patient not found"
**Solution:** Verify the patient ID exists in the database.

#### 4. "Unauthorized access"
**Solution:** Ensure you're sending a valid Bearer token in the Authorization header.

### Debug Steps

1. **Check Server Logs:**
   ```bash
   # Look for OpenAI API errors
   tail -f server.log | grep -i openai
   ```

2. **Verify API Key:**
   ```bash
   # Test OpenAI API key directly
   curl -H "Authorization: Bearer $OPENAI_API_KEY" \
        https://api.openai.com/v1/models
   ```

3. **Test Patient Data:**
   ```bash
   # Verify patient exists and has data
   curl -X GET "http://localhost:5000/doctor/patient/PATIENT_ID/full-details" \
        -H "Authorization: Bearer YOUR_TOKEN"
   ```

---

## 💡 Best Practices

### For Developers
1. **Cache AI Summaries** - Avoid regenerating summaries for unchanged data
2. **Error Handling** - Always check the `success` field before using `ai_summary`
3. **Rate Limiting** - Implement client-side rate limiting for AI requests
4. **Fallback** - Provide fallback summaries when AI is unavailable

### For Medical Professionals
1. **Review AI Output** - Always review AI-generated summaries before making medical decisions
2. **Data Freshness** - Ensure patient data is up-to-date before generating summaries
3. **Comprehensive Analysis** - Use AI summaries as a starting point, not final diagnosis
4. **Documentation** - Keep records of AI-generated insights for future reference

---

## 📞 Support

For technical issues:
1. Check server logs for detailed error messages
2. Verify OpenAI API key configuration
3. Test with different patient IDs
4. Ensure network connectivity to OpenAI API

For medical concerns:
- AI summaries are for informational purposes only
- Always consult with qualified medical professionals
- Do not rely solely on AI-generated medical advice

---

**Note:** This endpoint requires OpenAI API access and may incur costs based on usage. Monitor your OpenAI API usage and costs regularly.
