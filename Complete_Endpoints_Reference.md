# 🚀 COMPLETE ENDPOINTS REFERENCE - app_mvc.py

## 📋 **OVERVIEW**
This file contains all the endpoints available in your `app_mvc.py` Flask application. The server runs on `http://localhost:5000` (or port 8000 if PORT environment variable is set).

---

## 🔐 **AUTHENTICATION ENDPOINTS**

### **1. Root Endpoint**
- **Method:** `GET`
- **URL:** `/`
- **Description:** API information and available endpoints
- **Auth Required:** No
- **Response:** API status, version, and endpoint list

### **2. Health Check**
- **Method:** `GET`
- **URL:** `/health`
- **Description:** Health check endpoint
- **Auth Required:** No
- **Response:** Server status and timestamp

---

## 🔑 **DOCTOR AUTHENTICATION**

### **3. Doctor Signup**
- **Method:** `POST`
- **URL:** `/doctor-signup`
- **Description:** Register a new doctor
- **Auth Required:** No
- **Request Body:**
```json
{
  "username": "doctor_username",
  "email": "doctor@example.com",
  "mobile": "1234567890",
  "password": "secure_password",
  "role": "doctor"
}
```

### **4. Doctor Send OTP**
- **Method:** `POST`
- **URL:** `/doctor-send-otp`
- **Description:** Send OTP to doctor email for verification
- **Auth Required:** No
- **Request Body:**
```json
{
  "email": "doctor@example.com"
}
```

### **5. Doctor Verify OTP**
- **Method:** `POST`
- **URL:** `/doctor-verify-otp`
- **Description:** Verify doctor OTP and complete registration
- **Auth Required:** No
- **Request Body:**
```json
{
  "email": "doctor@example.com",
  "otp": "123456",
  "jwt_token": "jwt_token_from_send_otp"
}
```

### **6. Doctor Login**
- **Method:** `POST`
- **URL:** `/doctor-login`
- **Description:** Doctor login endpoint
- **Auth Required:** No
- **Request Body:**
```json
{
  "email": "doctor@example.com",
  "password": "password123"
}
```

### **7. General Login**
- **Method:** `POST`
- **URL:** `/login`
- **Description:** Login for both doctors and patients
- **Auth Required:** No
- **Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

---

## 👨‍⚕️ **DOCTOR PROFILE ENDPOINTS**

### **8. Get Doctor Profile**
- **Method:** `GET`
- **URL:** `/doctor/profile/{doctor_id}`
- **Description:** Get doctor profile information
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **9. Update Doctor Profile**
- **Method:** `PUT`
- **URL:** `/doctor/profile/{doctor_id}`
- **Description:** Update doctor profile information
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **10. Complete Doctor Profile**
- **Method:** `POST`
- **URL:** `/doctor/complete-profile`
- **Description:** Complete doctor profile with additional information
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

---

## 👥 **PATIENT MANAGEMENT ENDPOINTS**

### **11. Get Doctor's Patients**
- **Method:** `GET`
- **URL:** `/doctor/patients`
- **Description:** Get all patients assigned to the logged-in doctor
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **12. Get Patient Details**
- **Method:** `GET`
- **URL:** `/doctor/patient/{patient_id}`
- **Description:** Get detailed patient information
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **13. Get Patient Full Details**
- **Method:** `GET`
- **URL:** `/doctor/patient/{patient_id}/full-details`
- **Description:** Get complete patient details with all health data
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **14. Get Patient AI Summary**
- **Method:** `GET`
- **URL:** `/doctor/patient/{patient_id}/ai-summary`
- **Description:** Get AI-powered medical summary for a patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

---

## 📅 **APPOINTMENT ENDPOINTS**

### **15. Get Doctor Appointments**
- **Method:** `GET`
- **URL:** `/doctor/appointments`
- **Description:** Get appointments for the logged-in doctor
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **16. Create Doctor Appointment**
- **Method:** `POST`
- **URL:** `/doctor/appointments`
- **Description:** Create new appointment for the logged-in doctor
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **17. Get Doctor Dashboard Stats**
- **Method:** `GET`
- **URL:** `/doctor/dashboard-stats`
- **Description:** Get dashboard statistics for the logged-in doctor
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

---

## 🏥 **PATIENT HEALTH DATA ENDPOINTS**

### **18. Get Medication History**
- **Method:** `GET`
- **URL:** `/medication/get-medication-history/{patient_id}`
- **Description:** Get medication history for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **19. Get Symptom Analysis Reports**
- **Method:** `GET`
- **URL:** `/symptoms/get-analysis-reports/{patient_id}`
- **Description:** Get symptom analysis reports for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **20. Get Food Entries**
- **Method:** `GET`
- **URL:** `/nutrition/get-food-entries/{patient_id}`
- **Description:** Get food entries for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **21. Get Tablet Tracking History**
- **Method:** `GET`
- **URL:** `/medication/get-tablet-tracking-history/{patient_id}`
- **Description:** Get tablet tracking history for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **22. Get Patient Profile**
- **Method:** `GET`
- **URL:** `/profile/{patient_id}`
- **Description:** Get patient profile information
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **23. Get Kick Count History**
- **Method:** `GET`
- **URL:** `/kick-count/get-kick-history/{patient_id}`
- **Description:** Get kick count history for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **24. Get Mental Health History**
- **Method:** `GET`
- **URL:** `/mental-health/history/{patient_id}`
- **Description:** Get mental health history for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **25. Get Prescription Documents**
- **Method:** `GET`
- **URL:** `/prescription/documents/{patient_id}`
- **Description:** Get prescription documents for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **26. Get Vital Signs History**
- **Method:** `GET`
- **URL:** `/vital-signs/history/{patient_id}`
- **Description:** Get vital signs history for patient
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

---

## 👤 **PATIENT AUTHENTICATION**

### **27. Patient Signup**
- **Method:** `POST`
- **URL:** `/patient/signup`
- **Description:** Register a new patient
- **Auth Required:** No
- **Request Body:**
```json
{
  "username": "patient_username",
  "email": "patient@example.com",
  "mobile": "1234567890",
  "password": "secure_password",
  "role": "patient"
}
```

### **28. Patient Verify OTP**
- **Method:** `POST`
- **URL:** `/patient/verify-otp`
- **Description:** Verify patient OTP and complete registration
- **Auth Required:** No
- **Request Body:**
```json
{
  "email": "patient@example.com",
  "otp": "123456",
  "jwt_token": "jwt_token_from_send_otp"
}
```

---

## 📋 **PATIENT CRUD OPERATIONS**

### **29. Create Patient**
- **Method:** `POST`
- **URL:** `/patients`
- **Description:** Create a new patient record
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`
- **Request Body:**
```json
{
  "full_name": "John Doe",
  "email": "john@example.com",
  "contact_number": "1234567890",
  "date_of_birth": "01/01/1990",
  "gender": "Male",
  "address": "123 Main St",
  "emergency_contact": "9876543210"
}
```

### **30. Get All Patients**
- **Method:** `GET`
- **URL:** `/patients`
- **Description:** Get all patients with pagination and search
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`
- **Query Parameters:**
  - `page` (optional): Page number (default: 1)
  - `limit` (optional): Items per page (default: 10)
  - `search` (optional): Search term

### **31. Get Patient by ID**
- **Method:** `GET`
- **URL:** `/patients/{patient_id}`
- **Description:** Get specific patient by ID
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **32. Update Patient**
- **Method:** `PUT`
- **URL:** `/patients/{patient_id}`
- **Description:** Update patient information
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **33. Delete Patient**
- **Method:** `DELETE`
- **URL:** `/patients/{patient_id}`
- **Description:** Delete patient record
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

### **34. Get Patients by Doctor**
- **Method:** `GET`
- **URL:** `/doctors/{doctor_id}/patients`
- **Description:** Get all patients assigned to a specific doctor
- **Auth Required:** Yes (JWT Token)
- **Headers:** `Authorization: Bearer {jwt_token}`

---

## 🔄 **OTP MANAGEMENT**

### **35. Resend OTP**
- **Method:** `POST`
- **URL:** `/resend-otp`
- **Description:** Resend OTP for verification
- **Auth Required:** No
- **Request Body:**
```json
{
  "email": "user@example.com",
  "role": "doctor" // or "patient"
}
```

---

## 🐛 **DEBUG ENDPOINTS**

### **36. Debug Environment Variables**
- **Method:** `GET`
- **URL:** `/debug/env`
- **Description:** Debug environment variables
- **Auth Required:** No

### **37. Debug Database Connection**
- **Method:** `GET`
- **URL:** `/debug/db`
- **Description:** Debug database connection status
- **Auth Required:** No

### **38. Debug Doctors Data**
- **Method:** `GET`
- **URL:** `/debug/doctors`
- **Description:** Debug doctor data in database
- **Auth Required:** No

### **39. Debug Test Login**
- **Method:** `POST`
- **URL:** `/debug/test-login`
- **Description:** Debug test login with specific credentials
- **Auth Required:** No
- **Request Body:**
```json
{
  "email": "test@example.com",
  "password": "test123"
}
```

### **40. Debug OpenAI Configuration**
- **Method:** `GET`
- **URL:** `/debug/openai-config`
- **Description:** Debug OpenAI API key configuration
- **Auth Required:** No

### **41. Test OpenAI API**
- **Method:** `GET`
- **URL:** `/debug/test-openai`
- **Description:** Test OpenAI API connection
- **Auth Required:** No

---

## 📊 **STATUS CODES**

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 404 | Not Found |
| 409 | Conflict (Duplicate) |
| 500 | Internal Server Error |

---

## 🔧 **AUTHENTICATION**

Most endpoints require JWT authentication. Include the token in the Authorization header:
```
Authorization: Bearer {your_jwt_token}
```
