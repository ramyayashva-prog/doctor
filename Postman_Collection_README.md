# Doctor App API - Postman Collection

## 📋 Overview
This Postman collection contains all the API endpoints for the Doctor Patient Management System. The collection includes sample requests, responses, and environment variables for easy testing.

## 🚀 Quick Start

### 1. Import the Collection
1. Open Postman
2. Click "Import" button
3. Select the `Doctor_App_Postman_Collection.json` file
4. The collection will be imported with all endpoints

### 2. Set Up Environment Variables
The collection uses the following variables:
- `baseUrl`: `http://localhost:8000` (or your server URL)
- `token`: JWT token (will be set automatically after login)
- `doctorId`: `D17587987732214` (sample doctor ID)
- `patientId`: `PAT175820015455746A` (sample patient ID)

### 3. Start Testing
1. **First, run the Health Check** to ensure the server is running
2. **Login as Doctor** to get the JWT token
3. **Use other endpoints** - the token will be automatically included

## 📚 API Endpoints

### 🔐 Authentication
- **POST** `/doctor-login` - Doctor login
- **POST** `/doctor-signup` - Doctor registration

### 📊 Dashboard
- **GET** `/doctor/dashboard-stats` - Get dashboard statistics
- **GET** `/doctor/patients` - Get all patients
- **GET** `/doctor/appointments` - Get all appointments
- **POST** `/doctor/appointments` - Create new appointment

### 👤 Patient Details
- **GET** `/doctor/patient/{patientId}` - Get patient details
- **GET** `/doctor/patient/{patientId}/full-details` - Get complete patient data
- **GET** `/doctor/patient/{patientId}/ai-summary` - Get AI-powered summary

### 🏥 Health Data
- **GET** `/medication/get-medication-history/{patientId}` - Medication history
- **GET** `/symptoms/get-analysis-reports/{patientId}` - Symptom reports
- **GET** `/nutrition/get-food-entries/{patientId}` - Food entries
- **GET** `/mental-health/history/{patientId}` - Mental health logs
- **GET** `/kick-count/get-kick-history/{patientId}` - Kick count logs
- **GET** `/prescription/documents/{patientId}` - Prescription documents
- **GET** `/vital-signs/history/{patientId}` - Vital signs history
- **GET** `/profile/{patientId}` - Patient profile

## 🔧 Sample Requests

### Doctor Login
```json
POST /doctor-login
{
  "email": "ramyayashva@gmail.com",
  "password": "password123"
}
```

### Create Appointment
```json
POST /doctor/appointments
{
  "patient_id": "PAT175820015455746A",
  "appointment_date": "2025-09-28",
  "appointment_time": "2:00 PM",
  "appointment_type": "Follow-up",
  "notes": "Follow-up appointment",
  "doctor_id": "D17587987732214"
}
```

## 📝 Response Examples

### Successful Login Response
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "doctor_id": "D17587987732214",
  "email": "ramyayashva@gmail.com",
  "username": "Dr. Ramya",
  "user": {
    "id": "D17587987732214",
    "email": "ramyayashva@gmail.com",
    "username": "Dr. Ramya",
    "role": "doctor"
  }
}
```

### Patient Full Details Response
```json
{
  "success": true,
  "patient_id": "PAT175820015455746A",
  "patient_info": {
    "full_name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "mobile": "+1234567890",
    "age": 28,
    "blood_type": "O+",
    "gender": "F",
    "is_pregnant": true,
    "status": "active"
  },
  "health_data": {
    "medication_logs": [],
    "symptom_analysis_reports": [...],
    "food_data": [...],
    "mental_health_logs": [...],
    "appointments": [...]
  },
  "summary": {
    "total_medications": 0,
    "total_symptoms": 1,
    "total_food_entries": 1,
    "total_mental_health": 1,
    "total_appointments": 1
  }
}
```

## 🔑 Authentication
Most endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## 🌐 Base URL
- **Local Development**: `http://localhost:8000`
- **Production**: Update the `baseUrl` variable in Postman

## 📊 Status Codes
- **200**: Success
- **201**: Created
- **400**: Bad Request
- **401**: Unauthorized
- **404**: Not Found
- **500**: Internal Server Error

## 🚨 Error Responses
```json
{
  "error": "Error message description",
  "success": false
}
```

## 💡 Tips
1. **Always check the Health endpoint first** to ensure the server is running
2. **Login first** to get the JWT token for authenticated endpoints
3. **Use the environment variables** to easily switch between different patient/doctor IDs
4. **Check the response examples** in each request to understand the expected data structure
5. **The AI Summary endpoint** requires an OpenAI API key to be configured in the backend

## 🔄 Workflow
1. Health Check → 2. Doctor Login → 3. Get Dashboard Stats → 4. Get Patients → 5. Get Patient Details → 6. Get Health Data → 7. Create Appointment

## 📞 Support
If you encounter any issues:
1. Check that the backend server is running on the correct port
2. Verify the MongoDB connection is working
3. Ensure all required environment variables are set
4. Check the server logs for detailed error messages

---

**Happy Testing! 🎉**

