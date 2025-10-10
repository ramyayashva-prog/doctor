# Appointment Endpoints - Complete Summary

## 🎯 All Appointment Endpoints

### **Base URL:** `http://localhost:8000`

---

## 📋 Complete Appointment CRUD Operations

| # | Method | Endpoint | Description | Status |
|---|--------|----------|-------------|--------|
| 1 | GET | `/doctor/appointments` | Get all appointments | ✅ Working |
| 2 | GET | `/doctor/appointments?patient_id={id}` | Get patient appointments | ✅ Working |
| 3 | GET | `/doctor/appointments/{appointment_id}` | Get single appointment | ✅ Working |
| 4 | POST | `/doctor/appointments` | Create appointment | ✅ Working |
| 5 | PUT | `/doctor/appointments/{appointment_id}` | Update appointment | ✅ Working |
| 6 | DELETE | `/doctor/appointments/{appointment_id}` | Delete appointment | ✅ Working |

---

## 📖 Detailed Documentation

### **1. Get All Appointments**

**Endpoint:** `GET /doctor/appointments`

**Query Parameters:**
- `patient_id` (optional) - Filter by patient
- `date` (optional) - Filter by date
- `status` (optional) - Filter by status

**Example:**
```bash
GET http://localhost:8000/doctor/appointments
GET http://localhost:8000/doctor/appointments?status=scheduled
```

**Response:**
```json
{
  "success": true,
  "appointments": [...],
  "total_count": 82
}
```

---

### **2. Get Patient Appointments**

**Endpoint:** `GET /doctor/appointments?patient_id={patient_id}`

**Example:**
```bash
GET http://localhost:8000/doctor/appointments?patient_id=PAT17576730523DFD2A
```

**Response:**
```json
{
  "success": true,
  "appointments": [
    {
      "appointment_id": "68d57d8052eb7b568d9a0848",
      "patient_id": "PAT17576730523DFD2A",
      "patient_name": "kdkdkkr",
      "appointment_date": "2025-01-26",
      "appointment_time": "10:00 AM",
      "appointment_type": "Consultation",
      "appointment_status": "scheduled",
      "notes": "Test appointment"
    }
  ],
  "total_count": 2
}
```

---

### **3. Get Single Appointment by ID** ✨ NEW

**Endpoint:** `GET /doctor/appointments/{appointment_id}`

**Example:**
```bash
GET http://localhost:8000/doctor/appointments/68e6494cb0724d5e547834dc
```

**Response:**
```json
{
  "success": true,
  "appointment": {
    "appointment_id": "68e6494cb0724d5e547834dc",
    "patient_id": "PAT17576730523DFD2A",
    "patient_name": "kdkdkkr",
    "appointment_date": "2024-12-20",
    "appointment_time": "3:00 PM",
    "appointment_type": "Follow-up",
    "appointment_status": "scheduled",
    "notes": "Test single appointment GET",
    "doctor_id": "",
    "created_at": "2025-10-08T16:51:48.970459",
    "updated_at": "2025-10-08T16:51:48.970602",
    "status": "active"
  }
}
```

---

### **4. Create Appointment**

**Endpoint:** `POST /doctor/appointments`

**Request Body:**
```json
{
  "patient_id": "PAT123456",
  "appointment_date": "2024-01-15",
  "appointment_time": "10:00 AM",
  "appointment_type": "General",
  "appointment_mode": "in-person",
  "notes": "Regular checkup",
  "doctor_id": "D17597286260221902"
}
```

**Required Fields:**
- ✅ `patient_id`
- ✅ `appointment_date`
- ✅ `appointment_time`

**Optional Fields:**
- `appointment_type` (default: "General")
- `appointment_mode` (default: "in-person")
- `video_link` (for video-call mode)
- `notes`
- `doctor_id`

**Response (201):**
```json
{
  "appointment_id": "68e615d5166ba6407219b671",
  "message": "Appointment created successfully"
}
```

---

### **5. Update Appointment**

**Endpoint:** `PUT /doctor/appointments/{appointment_id}`

**Request Body (all fields optional):**
```json
{
  "appointment_date": "2024-01-16",
  "appointment_time": "2:00 PM",
  "appointment_type": "Follow-up",
  "appointment_mode": "video-call",
  "video_link": "https://meet.google.com/xyz",
  "appointment_status": "rescheduled",
  "notes": "Updated appointment"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Appointment updated successfully",
  "appointment_id": "68e615d5166ba6407219b671"
}
```

---

### **6. Delete Appointment**

**Endpoint:** `DELETE /doctor/appointments/{appointment_id}`

**Example:**
```bash
DELETE http://localhost:8000/doctor/appointments/68e615d5166ba6407219b671
```

**Response (200):**
```json
{
  "success": true,
  "message": "Appointment deleted successfully",
  "appointment_id": "68e615d5166ba6407219b671"
}
```

---

## 🎨 Appointment Modes

| Mode | Value | Use Case |
|------|-------|----------|
| In-Person | `in-person` | Physical clinic visit |
| Video Call | `video-call` | Online video consultation |
| Phone Call | `phone-call` | Phone consultation |
| Home Visit | `home-visit` | Doctor visits patient |

---

## 📱 Flutter Integration

### **Get Single Appointment:**
```dart
Future<Map<String, dynamic>> getAppointment(String appointmentId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/doctor/appointments/$appointmentId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

### **Get Patient Appointments:**
```dart
Future<Map<String, dynamic>> getPatientAppointments(String patientId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/doctor/appointments?patient_id=$patientId'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  return json.decode(response.body);
}
```

---

## 🧪 Testing Commands

### **PowerShell:**

```powershell
# Get all appointments
Invoke-RestMethod -Uri "http://localhost:8000/doctor/appointments"

# Get patient appointments
Invoke-RestMethod -Uri "http://localhost:8000/doctor/appointments?patient_id=PAT17576730523DFD2A"

# Get single appointment by ID
Invoke-RestMethod -Uri "http://localhost:8000/doctor/appointments/68e6494cb0724d5e547834dc"

# Create appointment
$body = @{
    patient_id = "PAT123456"
    appointment_date = "2024-01-15"
    appointment_time = "10:00 AM"
    appointment_type = "General"
    notes = "Test"
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8000/doctor/appointments" -Method POST -Body $body -ContentType "application/json"

# Update appointment
$update = @{
    appointment_time = "2:00 PM"
    notes = "Updated"
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8000/doctor/appointments/68e6494cb0724d5e547834dc" -Method PUT -Body $update -ContentType "application/json"

# Delete appointment
Invoke-RestMethod -Uri "http://localhost:8000/doctor/appointments/68e6494cb0724d5e547834dc" -Method DELETE
```

---

## ✅ All Endpoints Tested & Working

- ✅ GET all appointments - 200 OK
- ✅ GET patient appointments - 200 OK
- ✅ GET single appointment - 200 OK ✨
- ✅ POST create appointment - 201 Created
- ✅ PUT update appointment - 200 OK
- ✅ DELETE appointment - 200 OK

---

## 🎉 Complete!

You now have **6 fully functional appointment endpoints** including:
- **List all** appointments
- **Filter by patient** ID
- **Get single** appointment by ID ✨
- **Create** new appointments
- **Update** existing appointments
- **Delete** appointments

**Everything is ready to use!** 🚀


