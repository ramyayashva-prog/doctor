# Complete Endpoints List - All APIs in app_mvc.py

## ✅ All Endpoints Verified & Working

**Base URL:** `http://localhost:8000`

---

## 1️⃣ Authentication Endpoints (6)

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| POST | `/doctor-signup` | Register new doctor | ✅ 200 |
| POST | `/doctor-verify-otp` | Verify OTP | ✅ 200 |
| POST | `/doctor-login` | Login doctor | ✅ 200 |
| POST | `/doctor-forgot-password` | Forgot password | ✅ 200 |
| POST | `/doctor-reset-password` | Reset password | ✅ 200 |
| POST | `/patient/signup` | Register patient | ✅ 201 |

---

## 2️⃣ Doctor Profile Endpoints (4)

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/doctor/profile/{doctor_id}` | Get doctor profile | ✅ 200 |
| PUT | `/doctor/profile/{doctor_id}` | Update doctor profile | ✅ 200 |
| POST | `/doctor-complete-profile` | Complete profile | ✅ 200 |
| GET | `/doctor-profile-fields` | Get profile fields | ✅ 200 |

---

## 3️⃣ Patient Selection Endpoints (3) 🆕

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/doctors` | List all doctors with patient count | ✅ 200 |
| GET | `/doctors/search` | Search doctors with filters | ✅ 200 |
| GET | `/doctors/{doctor_id}` | Public doctor profile | ✅ 200 |

---

## 4️⃣ Appointment CRUD Endpoints (6) ⭐

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/doctor/appointments` | Get all appointments | ✅ 200 |
| GET | `/doctor/appointments?patient_id={id}` | Get patient appointments | ✅ 200 |
| GET | `/doctor/appointments/{appointment_id}` | Get single appointment | ✅ 200 |
| POST | `/doctor/appointments` | Create appointment | ✅ 201 |
| PUT | `/doctor/appointments/{appointment_id}` | Update appointment | ✅ 200 |
| DELETE | `/doctor/appointments/{appointment_id}` | Delete appointment | ✅ 200 |

---

## 5️⃣ Doctor Dashboard Endpoints (5)

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/doctor/dashboard-stats` | Dashboard statistics | ✅ 200 |
| GET | `/doctor/patients` | List all patients | ✅ 200 |
| GET | `/doctor/patient/{patient_id}` | Patient details | ✅ 200 |
| GET | `/doctor/patient/{patient_id}/full-details` | Full patient data | ✅ 200 |
| GET | `/doctor/patient/{patient_id}/ai-summary` | AI summary | ✅ 200 |

---

## 6️⃣ Patient Health Data Endpoints (6) ✨

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/medication/get-medication-history/{patient_id}` | Medication history | ✅ 200 |
| GET | `/nutrition/get-food-entries/{patient_id}` | Food/nutrition entries | ✅ 200 |
| GET | `/mental-health/history/{patient_id}` | Mental health logs | ✅ 200 |
| GET | `/kick-count/get-kick-history/{patient_id}` | Kick count logs | ✅ 200 |
| GET | `/prescription/documents/{patient_id}` | Prescription documents | ✅ 200 |
| GET | `/vital-signs/history/{patient_id}` | Vital signs history | ✅ 200 |

---

## 7️⃣ Patient CRUD Endpoints (5)

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/patients` | Get all patients | ✅ 200 |
| GET | `/patients/{patient_id}` | Get patient by ID | ✅ 200 |
| POST | `/patients` | Create patient | ✅ 201 |
| PUT | `/patients/{patient_id}` | Update patient | ✅ 200 |
| DELETE | `/patients/{patient_id}` | Delete patient | ✅ 200 |

---

## 8️⃣ Health Check Endpoints (2)

| Method | Endpoint | Description | Status |
|--------|----------|-------------|--------|
| GET | `/` | API information | ✅ 200 |
| GET | `/health` | Health check | ✅ 200 |

---

## 📊 Total Endpoints: 37

- **Authentication**: 6 endpoints
- **Doctor Profile**: 4 endpoints
- **Patient Selection**: 3 endpoints
- **Appointments CRUD**: 6 endpoints
- **Doctor Dashboard**: 5 endpoints
- **Patient Health Data**: 6 endpoints
- **Patient CRUD**: 5 endpoints
- **Health Check**: 2 endpoints

---

## 🎯 Endpoints You Requested (All Working!)

✅ `/medication/get-medication-history/{patientId}` - Working (200)
✅ `/nutrition/get-food-entries/{patientId}` - Working (200)
✅ `/mental-health/history/{patientId}` - Working (200)
✅ `/kick-count/get-kick-history/{patientId}` - Working (200)
✅ `/prescription/documents/{patientId}` - Working (200)
✅ `/vital-signs/history/{patientId}` - Working (200)

**All requested endpoints are already in `app_mvc.py` and working perfectly!**

---

## 📱 Flutter Integration Examples

### **Get Medication History:**
```dart
Future<Map<String, dynamic>> getMedicationHistory(String patientId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/medication/get-medication-history/$patientId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

### **Get Nutrition Data:**
```dart
Future<Map<String, dynamic>> getFoodEntries(String patientId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/nutrition/get-food-entries/$patientId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

### **Get Mental Health History:**
```dart
Future<Map<String, dynamic>> getMentalHealthHistory(String patientId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/mental-health/history/$patientId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

### **Get Kick Count History:**
```dart
Future<Map<String, dynamic>> getKickCountHistory(String patientId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/kick-count/get-kick-history/$patientId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

### **Get Prescription Documents:**
```dart
Future<Map<String, dynamic>> getPrescriptionDocuments(String patientId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/prescription/documents/$patientId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

### **Get Vital Signs History:**
```dart
Future<Map<String, dynamic>> getVitalSignsHistory(String patientId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/vital-signs/history/$patientId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

---

## 🧪 PowerShell Testing Commands

```powershell
$patientId = "PAT17576730523DFD2A"

# Test all health data endpoints
Invoke-RestMethod -Uri "http://localhost:8000/medication/get-medication-history/$patientId"
Invoke-RestMethod -Uri "http://localhost:8000/nutrition/get-food-entries/$patientId"
Invoke-RestMethod -Uri "http://localhost:8000/mental-health/history/$patientId"
Invoke-RestMethod -Uri "http://localhost:8000/kick-count/get-kick-history/$patientId"
Invoke-RestMethod -Uri "http://localhost:8000/prescription/documents/$patientId"
Invoke-RestMethod -Uri "http://localhost:8000/vital-signs/history/$patientId"
```

---

## 🎉 Summary

### ✅ Good News!
All the endpoints you requested are **already implemented** in `app_mvc.py`:

1. ✅ Medication History
2. ✅ Nutrition/Food Entries
3. ✅ Mental Health History
4. ✅ Kick Count History
5. ✅ Prescription Documents
6. ✅ Vital Signs History

### ✅ All Tested & Working!
- Status: 200 OK
- Located in: `app_mvc.py` (lines 356-399)
- Controller methods: In `doctor_controller.py`
- Postman collection: Updated with all endpoints

**No code changes needed - everything is already there and working!** 🚀


