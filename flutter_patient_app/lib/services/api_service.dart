import 'dart:convert';
import 'dart:async'; // Add this for TimeoutException
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../config/n8n_config.dart';
import '../providers/auth_provider.dart';

class ApiService {
  static String? _authToken;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void clearAuthToken() {
    _authToken = null;
  }

  static Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String mobile,
    required String password,
    required String role,
  }) async {
    try {
      // Use different endpoints for different roles
      String endpoint = role == 'doctor' ? '/doctor-signup' : ApiConfig.signupEndpoint;
      
      print('🔍 API Service - signup:');
      print('  URL: ${ApiConfig.baseUrl}$endpoint');
      print('  Role: $role');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
        body: json.encode({
          'username': username,
          'email': email,
          'mobile': mobile,
          'password': password,
          'role': role,
        }),
      );

      print('🔍 API Service - signup Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');
      
      // Parse response
      final responseData = json.decode(response.body);
      
      // CRITICAL: Check for JWT token in response
      if (role == 'doctor' && responseData.containsKey('jwt_token')) {
        print('✅ JWT token found in signup response');
        print('  JWT token length: ${responseData['jwt_token'].toString().length}');
        print('  JWT token preview: ${responseData['jwt_token'].toString().substring(0, 50)}...');
      } else if (role == 'doctor') {
        print('❌ JWT token NOT found in signup response');
        print('  Available keys: ${responseData.keys.toList()}');
        print('  Full response: $responseData');
      }

      return responseData;
    } catch (e) {
      print('🔍 API Service - signup Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String role,
    String? jwtToken,
  }) async {
    try {
      final requestData = {
        'email': email,
        'otp': otp,
        'role': role,
      };
      
      // Add JWT token for doctor verification
      if (role == 'doctor' && jwtToken != null) {
        requestData['jwt_token'] = jwtToken;
      }

      // Use different endpoints for different roles
      String endpoint = role == 'doctor' ? '/doctor-verify-otp' : ApiConfig.verifyOtpEndpoint;
      
      print('🔍 API Service - verifyOtp:');
      print('  URL: ${ApiConfig.baseUrl}$endpoint');
      print('  Role: $role');
      print('  Request Data: ${json.encode(requestData)}');
      print('  JWT Token in request: ${jwtToken != null ? 'Present' : 'Missing'}');
      if (jwtToken != null) {
        print('  JWT Token length: ${jwtToken.length}');
        print('  JWT Token preview: ${jwtToken.substring(0, 50)}...');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
        body: json.encode(requestData),
      );

      print('🔍 API Service - verifyOtp Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('🔍 API Service - verifyOtp Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String loginIdentifier,
    required String password,
    required String role,
  }) async {
    try {
      // Use doctor-login endpoint for doctors only
      String endpoint = '${ApiConfig.baseUrl}/doctor-login';
      Map<String, dynamic> requestBody = {
        'email': loginIdentifier,  // Doctors can use email or doctor_id
          'password': password,
        };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: json.encode(requestBody),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // Doctor-specific API calls
  Future<Map<String, dynamic>> getDoctorPatients(String doctorId) async {
    try {
      if (doctorId.isEmpty) {
        return {'error': 'Doctor ID is required'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patients?doctor_id=$doctorId'),
        headers: _getAuthHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientDetails(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patient/$patientId'),
        headers: _getAuthHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getDoctorDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/dashboard-stats'),
        headers: _getAuthHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // Appointments CRUD operations
  Future<Map<String, dynamic>> getAppointments({required String doctorId, String? patientId, String? date, String? status}) async {
    try {
      String url = '${ApiConfig.baseUrl}/doctor/appointments';
      List<String> queryParams = [];
      
      // Always include doctor_id
      queryParams.add('doctor_id=$doctorId');
      
      if (patientId != null) queryParams.add('patient_id=$patientId');
      if (date != null) queryParams.add('date=$date');
      if (status != null) queryParams.add('status=$status');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getAuthHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createAppointment({
    required String patientId,
    required String appointmentDate,
    required String appointmentTime,
    String? appointmentType,
    String? notes,
    String? doctorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctor/appointments'),
        headers: _getAuthHeaders(),
        body: json.encode({
          'patient_id': patientId,
          'appointment_date': appointmentDate,
          'appointment_time': appointmentTime,
          'appointment_type': appointmentType ?? 'General',
          'notes': notes ?? '',
          'doctor_id': doctorId ?? '',
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAppointment({
    required String appointmentId,
    String? appointmentDate,
    String? appointmentTime,
    String? appointmentType,
    String? appointmentStatus,
    String? notes,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (appointmentDate != null) updateData['appointment_date'] = appointmentDate;
      if (appointmentTime != null) updateData['appointment_time'] = appointmentTime;
      if (appointmentType != null) updateData['appointment_type'] = appointmentType;
      if (appointmentStatus != null) updateData['appointment_status'] = appointmentStatus;
      if (notes != null) updateData['notes'] = notes;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctor/appointments/$appointmentId'),
        headers: _getAuthHeaders(),
        body: json.encode(updateData),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAppointment(String appointmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/doctor/appointments/$appointmentId'),
        headers: _getAuthHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Map<String, String> _getAuthHeaders() {
    final headers = Map<String, String>.from(_headers);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String loginIdentifier,
    String role = 'patient',
  }) async {
    try {
      // Use different endpoints based on role
      String endpoint = role == 'doctor' 
          ? '/doctor-forgot-password' 
          : ApiConfig.forgotPasswordEndpoint;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
        body: json.encode({
          'login_identifier': loginIdentifier,
          'role': role,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    String role = 'patient',
  }) async {
    try {
      // Use different endpoints based on role
      String endpoint = role == 'doctor' 
          ? '/doctor-reset-password' 
          : ApiConfig.resetPasswordEndpoint;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
          'role': role,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> completeProfile({
    required String patientId,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String bloodType,
    required String weight,
    required String height,
    required bool isPregnant,
    String? lastPeriodDate,
    String? pregnancyWeek,
    String? expectedDeliveryDate,
    required String emergencyName,
    required String emergencyRelationship,
    required String emergencyPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.completeProfileEndpoint}'),
        headers: _headers,
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'date_of_birth': dateOfBirth,
          'blood_type': bloodType,
          'weight': weight,
          'height': height,
          'is_pregnant': isPregnant,
          'last_period_date': lastPeriodDate,
          'pregnancy_week': pregnancyWeek,
          'expected_delivery_date': expectedDeliveryDate,
          'emergency_name': emergencyName,
          'emergency_relationship': emergencyRelationship,
          'emergency_phone': emergencyPhone,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProfile({
    required String patientId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getProfileEndpoint}/$patientId'),
        headers: _headers,
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> completeDoctorProfile({
    required String doctorId,
    required String firstName,
    required String lastName,
    required String specialization,
    required String licenseNumber,
    int? experienceYears,
    String? hospitalName,
    String? address,
    String? city,
    String? state,
    String? pincode,
    int? consultationFee,
    List<String>? languages,
    List<String>? qualifications,
  }) async {
    try {
      final requestData = {
        'doctor_id': doctorId,
        'first_name': firstName,
        'last_name': lastName,
        'specialization': specialization,
        'license_number': licenseNumber,
        'experience_years': experienceYears ?? 0,
        'hospital_name': hospitalName ?? '',
        'address': address ?? '',
        'city': city ?? '',
        'state': state ?? '',
        'pincode': pincode ?? '',
        'consultation_fee': consultationFee ?? 0,
        'languages': languages ?? [],
        'qualifications': qualifications ?? [],
      };
      
      print('🔍 API Service - completeDoctorProfile:');
      print('  URL: ${ApiConfig.baseUrl}/doctor-complete-profile');
      print('  Headers: $_headers');
      print('  Request Data: ${json.encode(requestData)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctor-complete-profile'),
        headers: _headers,
        body: json.encode(requestData),
      );
      
      print('🔍 API Service - Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('🔍 API Service - Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendOtpEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyToken({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/verify-token'),
        headers: _headers,
        body: json.encode({
          'token': token,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveSleepLog(Map<String, dynamic> sleepData) async {
    try {
      // DEBUG LOGGING - See exactly what's being sent
      print('🔍 ===== API SERVICE DEBUG START =====');
      print('🔍 URL: ${ApiConfig.baseUrl}/save-sleep-log');
      print('🔍 Headers: $_headers');
      print('🔍 Sleep Data Received: $sleepData');
      print('🔍 Email Field: ${sleepData['email']}');
      print('🔍 JSON Encoded: ${json.encode(sleepData)}');
      print('🔍 ===== API SERVICE DEBUG END =====');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/save-sleep-log'),
        headers: _headers,
        body: json.encode(sleepData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save sleep log');
      }
    } catch (e) {
      throw Exception('Error saving sleep log: $e');
    }
  }

  // Save kick session data
  Future<Map<String, dynamic>> saveKickSession(Map<String, dynamic> kickData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/save-kick-session'),
        headers: _headers,
        body: json.encode(kickData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save kick session');
      }
    } catch (e) {
      throw Exception('Error saving kick session: $e');
    }
  }

  // Get kick history for a patient
  Future<Map<String, dynamic>> getKickHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get-kick-history/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get kick history');
      }
    } catch (e) {
      throw Exception('Error getting kick history: $e');
    }
  }

  // Analyze symptoms using quantum+LLM
  Future<Map<String, dynamic>> analyzeSymptoms(Map<String, dynamic> symptomData) async {
    try {
      print('🔍 Symptom Analysis API Call:');
      print('🔍 URL: ${ApiConfig.baseUrl}/symptoms/assist');
      print('🔍 Data: $symptomData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/symptoms/assist'),
        headers: _headers,
        body: json.encode(symptomData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Analysis Result: $result');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Save symptom analysis report to backend
  Future<Map<String, dynamic>> saveSymptomAnalysisReport(Map<String, dynamic> reportData) async {
    try {
      print('🔍 Saving Symptom Analysis Report:');
      print('🔍 URL: ${ApiConfig.baseUrl}/symptoms/save-analysis-report');
      print('🔍 Data: $reportData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/symptoms/save-analysis-report'),
        headers: _headers,
        body: json.encode(reportData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Report Saved Successfully: $result');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get symptom analysis reports history
  Future<Map<String, dynamic>> getSymptomAnalysisReports(String patientId) async {
    try {
      print('🔍 Getting Symptom Analysis Reports:');
      print('🔍 URL: ${ApiConfig.baseUrl}/symptoms/get-analysis-reports/$patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/symptoms/get-analysis-reports/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Reports Retrieved: ${result['totalReports']} reports');
        print('🔍 Full response keys: ${result.keys.toList()}');
        print('🔍 Analysis reports count: ${result['analysis_reports']?.length ?? 0}');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Save medication log to backend
  Future<Map<String, dynamic>> saveMedicationLog(Map<String, dynamic> medicationData) async {
    try {
      print('🔍 Saving Medication Log:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/save-medication-log');
      print('🔍 Data: $medicationData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/save-medication-log'),
        headers: _headers,
        body: json.encode(medicationData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Medication Log Saved Successfully: $result');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get medication history
  Future<Map<String, dynamic>> getMedicationHistory(String patientId) async {
    try {
      print('🔍 Getting Medication History:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/get-medication-history/$patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medication/get-medication-history/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Medication History Retrieved: ${result['totalEntries']} entries');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get upcoming dosages and alerts
  Future<Map<String, dynamic>> getUpcomingDosages(String patientId) async {
    try {
      print('🔍 Getting Upcoming Dosages:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/get-upcoming-dosages/$patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medication/get-upcoming-dosages/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Upcoming Dosages Retrieved: ${result['total_upcoming']} dosages');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Save tablet taken for daily tracking
  Future<Map<String, dynamic>> saveTabletTaken(Map<String, dynamic> tabletData) async {
    try {
      print('🔍 Saving Tablet Taken:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/save-tablet-taken');
      print('🔍 Data: $tabletData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/save-tablet-taken'),
        headers: _headers,
        body: json.encode(tabletData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Tablet Taken Saved Successfully: $result');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Save tablet tracking data in medication_daily_tracking array
  Future<Map<String, dynamic>> saveTabletTracking(Map<String, dynamic> tabletData) async {
    try {
      print('🔍 Saving Tablet Tracking in medication_daily_tracking array:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/save-tablet-tracking');
      print('🔍 Data: $tabletData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/save-tablet-tracking'),
        headers: _headers,
        body: json.encode(tabletData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Tablet Tracking Saved Successfully in medication_daily_tracking array: $result');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get tablet tracking history from medication_daily_tracking array
  Future<Map<String, dynamic>> getTabletTrackingHistory(String patientId) async {
    try {
      print('🔍 Getting Tablet Tracking History from medication_daily_tracking array:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/get-tablet-tracking-history/$patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medication/get-tablet-tracking-history/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Tablet Tracking History Retrieved from medication_daily_tracking array: ${result['totalEntries'] ?? 0} entries');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Upload prescription details and dosage information
  Future<Map<String, dynamic>> uploadPrescription(Map<String, dynamic> prescriptionData) async {
    try {
      print('🔍 Uploading Prescription:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/upload-prescription');
      print('🔍 Data: $prescriptionData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/upload-prescription'),
        headers: _headers,
        body: json.encode(prescriptionData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Prescription Uploaded Successfully: $result');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get prescription details from patient profile data
  Future<Map<String, dynamic>> getPrescriptionDetails(String patientId) async {
    try {
      print('🔍 Getting Prescription Details from patient profile:');
      print('🔍 URL: ${ApiConfig.baseUrl}/profile/$patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        // Extract prescription data from patient profile
        final prescriptions = result['prescriptions'] ?? [];
        print('🔍 Prescription Details Retrieved: ${prescriptions.length} prescriptions from profile');
        return {'prescriptions': prescriptions, 'status': 'success'};
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Update prescription status
  Future<Map<String, dynamic>> updatePrescriptionStatus(String patientId, String prescriptionId, String status) async {
    try {
      print('🔍 Updating Prescription Status:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/update-prescription-status/$patientId/$prescriptionId');
      print('🔍 Status: $status');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/medication/update-prescription-status/$patientId/$prescriptionId'),
        headers: _headers,
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Prescription Status Updated Successfully: $result');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Process prescription through N8N webhook
  Future<Map<String, dynamic>> processPrescriptionWithN8N(Map<String, dynamic> prescriptionData) async {
    try {
      // Get webhook URL from config
      final String n8nWebhookUrl = N8NConfig.getWebhookUrl('prescription');
      
      // Check if webhook is configured
      if (!N8NConfig.isConfigured) {
        return {
          'error': 'N8N webhook not configured. Please update n8n_config.dart with your webhook URLs.',
          'step': 'configuration_error'
        };
      }
      
      print('🔍 Processing Prescription with N8N:');
      print('🔍 N8N Webhook URL: $n8nWebhookUrl');
      print('🔍 Data: $prescriptionData');
      
      final response = await http.post(
        Uri.parse(n8nWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(prescriptionData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 N8N Processing Successful: $result');
        return result;
      } else {
        print('❌ N8N API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'N8N API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ N8N Network Error: $e');
      return {'error': 'N8N Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> processPrescriptionWithOCRAndN8N({
    required String patientId,
    required String medicationName,
    required String filename,
    required String extractedText,
  }) async {
    try {
      print('🔍 Processing prescription with OCR and N8N webhook...');
      
      // First, process the document with OCR
      final ocrResult = await processPrescriptionDocument(
        patientId,
        medicationName,
        [], // Empty fileBytes since we already have extracted text
        filename,
      );

      if (!ocrResult['success']) {
        return ocrResult;
      }

      // Then send to N8N webhook
      final n8nResult = await processPrescriptionWithN8N({
        'patient_id': patientId,
        'medication_name': medicationName,
        'extracted_text': extractedText,
        'filename': filename,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Prescription processed successfully with OCR and N8N',
        'ocr_result': ocrResult,
        'n8n_result': n8nResult,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      print('❌ Error in processPrescriptionWithOCRAndN8N: $e');
      return {
        'success': false,
        'message': 'Error processing prescription: $e',
        'error': e.toString(),
      };
    }
  }

  // Process prescription document with OCR
  Future<Map<String, dynamic>> processPrescriptionDocument(
    String patientId,
    String medicationName,
    List<int> fileBytes,
    String filename,
  ) async {
    try {
      print('🔍 Processing Prescription Document with OCR:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/process-prescription-document');
      print('🔍 Patient ID: $patientId');
      print('🔍 Medication Name: $medicationName');
      print('🔍 Filename: $filename');
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/medication/process-prescription-document'),
      );
      
      // Add form fields
      request.fields['patient_id'] = patientId;
      request.fields['medication_name'] = medicationName;
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 OCR Document Processing Successful: $result');
        return result;
      } else {
        print('❌ OCR API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'OCR API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ OCR Network Error: $e');
      return {'error': 'OCR Network error: $e'};
    }
  }

  // Process prescription text for structured extraction
  Future<Map<String, dynamic>> processPrescriptionText(
    String patientId,
    String prescriptionText,
  ) async {
    try {
      print('🔍 Processing Prescription Text:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/process-prescription-text');
      print('🔍 Patient ID: $patientId');
      print('🔍 Text Length: ${prescriptionText.length}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/process-prescription-text'),
        headers: _headers,
        body: json.encode({
          'patient_id': patientId,
          'text': prescriptionText,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Prescription Text Processing Successful: $result');
        return result;
      } else {
        print('❌ Text Processing API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'Text Processing API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Text Processing Network Error: $e');
      return {'error': 'Text Processing Network error: $e'};
    }
  }

  // Get tablet tracking history
  Future<Map<String, dynamic>> getTabletHistory(String patientId) async {
    try {
      print('🔍 Getting Tablet History:');
      print('🔍 URL: ${ApiConfig.baseUrl}/medication/get-tablet-history/$patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medication/get-tablet-history/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Tablet History Retrieved: ${result['totalEntries']} entries');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Process prescription with OCR and send to N8N webhook using medication folder service
  Future<Map<String, dynamic>> processPrescriptionWithMedicationWebhook({
    required String patientId,
    required String medicationName,
    required String filename,
    required String extractedText,
  }) async {
    try {
      print('🚀 Processing prescription with medication folder webhook service...');
      
      // Send to the new endpoint that uses medication folder's webhook service
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/process-with-n8n-webhook'),
        headers: _headers,
        body: json.encode({
          'patient_id': patientId,
          'medication_name': medicationName,
          'extracted_text': extractedText,
          'filename': filename,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Medication webhook service processing successful');
        return result;
      } else {
        print('❌ Medication webhook service error: ${response.statusCode}');
        print('📄 Response: ${response.body}');
        return {
          'success': false,
          'error': 'Medication webhook service error: ${response.statusCode}',
          'response_body': response.body,
        };
      }

    } catch (e) {
      print('❌ Error in medication webhook service: $e');
      return {
        'success': false,
        'message': 'Error processing with medication webhook service: $e',
        'error': e.toString(),
      };
    }
  }

  // Process document with PaddleOCR for full text extraction
  Future<Map<String, dynamic>> processDocumentWithPaddleOCR({
    required String patientId,
    required String medicationName,
    required String filename,
    required List<int> fileBytes,
  }) async {
    try {
      print('🚀 Processing document with PaddleOCR for full text extraction...');
      print('🔍 File size: ${fileBytes.length} bytes');
      print('🔍 Filename: $filename');
      print('🔍 Patient ID: $patientId');
      print('🔍 Medication: $medicationName');
      print('🔍 Target URL: ${ApiConfig.baseUrl}/medication/process-with-paddleocr');
      
      // Validate file size (max 10MB)
      if (fileBytes.length > 10 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'File too large. Maximum size is 10MB.',
          'error': 'File size: ${fileBytes.length} bytes exceeds 10MB limit',
        };
      }
      
      // Create multipart request for file upload
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/medication/process-with-paddleocr'),
      );
      
      // Add text fields
      request.fields['patient_id'] = patientId;
      request.fields['medication_name'] = medicationName;
      
      // Add file to multipart request
      print('🔍 Adding file to multipart request...');
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );
      
      print('📤 Sending multipart request...');
      print('🔍 Request fields: ${request.fields}');
      print('🔍 Request files count: ${request.files.length}');
      
      // Send request with timeout and retry logic
      http.StreamedResponse? streamedResponse;
      int retryCount = 0;
      const int maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          print('🔄 Attempt ${retryCount + 1} of $maxRetries...');
          
          streamedResponse = await request.send().timeout(
            const Duration(seconds: 30), // 30 second timeout for file processing
            onTimeout: () {
              throw TimeoutException('File upload timed out after 30 seconds');
            },
          );
          
          print('📥 Received response stream, status: ${streamedResponse.statusCode}');
          break; // Success, exit retry loop
          
        } on TimeoutException catch (e) {
          retryCount++;
          print('⏰ Timeout on attempt $retryCount: $e');
          
          if (retryCount >= maxRetries) {
            return {
              'success': false,
              'message': 'File upload timed out after multiple attempts. The server might be busy.',
              'error': e.toString(),
            };
          }
          
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
          
        } catch (e) {
          retryCount++;
          print('❌ Error on attempt $retryCount: $e');
          
          if (retryCount >= maxRetries) {
            return {
              'success': false,
              'message': 'File upload failed after multiple attempts.',
              'error': e.toString(),
            };
          }
          
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }
      }
      
      if (streamedResponse == null) {
        return {
          'success': false,
          'message': 'Failed to get response from server after all retry attempts.',
          'error': 'No response received',
        };
      }
      
      // Process the response
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📄 Response status: ${response.statusCode}');
      print('📄 Response headers: ${response.headers}');
      print('📄 Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          print('✅ PaddleOCR processing successful');
          print('🔍 Full text content length: ${result['full_text_content']?.toString().length ?? 0}');
          print('🔍 Response keys: ${result.keys.toList()}');
          return result;
        } catch (e) {
          print('❌ Error parsing JSON response: $e');
          return {
            'success': false,
            'message': 'Server returned invalid JSON response.',
            'error': 'JSON parsing error: $e',
            'raw_response': response.body,
          };
        }
      } else {
        print('❌ PaddleOCR processing error: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return {
          'success': false,
          'error': 'PaddleOCR processing error: ${response.statusCode}',
          'response_body': response.body,
          'status_code': response.statusCode,
        };
      }

    } on TimeoutException catch (e) {
      print('❌ Timeout error in PaddleOCR processing: $e');
      return {
        'success': false,
        'message': 'File upload timed out. The file might be too large or the server is busy.',
        'error': e.toString(),
      };
    } on http.ClientException catch (e) {
      print('❌ Client exception in PaddleOCR processing: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'error': e.toString(),
      };
    } catch (e) {
      print('❌ Unexpected error in PaddleOCR processing: $e');
      return {
        'success': false,
        'message': 'Unexpected error occurred while processing the file.',
        'error': e.toString(),
      };
    }
  }

  // Test file upload endpoint
  Future<Map<String, dynamic>> testFileUpload({
    required String patientId,
    required String medicationName,
    required String filename,
    required List<int> fileBytes,
  }) async {
    try {
      print('🧪 Testing file upload endpoint...');
      print('🔍 File size: ${fileBytes.length} bytes');
      print('🔍 Filename: $filename');
      print('🔍 Patient ID: $patientId');
      print('🔍 Medication: $medicationName');
      print('🔍 Target URL: ${ApiConfig.baseUrl}/medication/test-file-upload');
      
      // Create multipart request for file upload test
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/medication/test-file-upload'),
      );
      
      // Add text fields
      request.fields['patient_id'] = patientId;
      request.fields['medication_name'] = medicationName;
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );
      
      print('📤 Sending test multipart request...');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15), // 15 second timeout for test
        onTimeout: () {
          throw TimeoutException('File upload test timed out after 15 seconds');
        },
      );
      
      print('📥 Received test response, status: ${streamedResponse.statusCode}');
      
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📄 Test response status: ${response.statusCode}');
      print('📄 Test response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ File upload test successful');
        return result;
      } else {
        print('❌ File upload test failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'File upload test failed: ${response.statusCode}',
          'response_body': response.body,
        };
      }

    } on TimeoutException catch (e) {
      print('❌ Timeout error in file upload test: $e');
      return {
        'success': false,
        'message': 'File upload test timed out.',
        'error': e.toString(),
      };
    } on http.ClientException catch (e) {
      print('❌ Client exception in file upload test: $e');
      return {
        'success': false,
        'message': 'Network error during file upload test.',
        'error': e.toString(),
      };
    } catch (e) {
      print('❌ Unexpected error in file upload test: $e');
      return {
        'success': false,
        'message': 'Unexpected error during file upload test.',
        'error': e.toString(),
      };
    }
  }

  // Test connectivity to different backend URLs
  Future<Map<String, dynamic>> testBackendConnectivity() async {
    final urls = ApiConfig.getAlternativeUrls();
    final results = <String, bool>{};
    
    print('🔍 Testing backend connectivity...');
    
    for (final url in urls) {
      try {
        print('📡 Testing: $url');
        final response = await http.get(
          Uri.parse('$url/medication/test-status'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          results[url] = true;
          print('✅ $url - CONNECTED');
        } else {
          results[url] = false;
          print('❌ $url - HTTP ${response.statusCode}');
        }
      } catch (e) {
        results[url] = false;
        print('❌ $url - ERROR: $e');
      }
    }
    
    // Find the best working URL
    String? bestUrl;
    for (final entry in results.entries) {
      if (entry.value == true) {
        bestUrl = entry.key;
        break;
      }
    }
    
    return {
      'success': bestUrl != null,
      'best_url': bestUrl,
      'all_results': results,
      'recommendation': bestUrl != null 
          ? 'Use: $bestUrl' 
          : 'No backend URLs are accessible. Check if Flask server is running.',
    };
  }

  // Analyze food with GPT-4
  Future<Map<String, dynamic>> analyzeFoodWithGPT4(String foodInput, int pregnancyWeek, String userId) async {
    try {
      print('🍎 Analyzing food with GPT-4:');
      print('🌐 Calling: ${ApiConfig.nutritionBaseUrl}/nutrition/analyze-with-gpt4');
      print('🔍 Food input: $foodInput');
      print('🔍 Pregnancy week: $pregnancyWeek');
      print('🔍 User ID: $userId');
      
      // Test backend connectivity first
      try {
        final healthResponse = await http.get(
          Uri.parse('${ApiConfig.nutritionBaseUrl}/nutrition/health'),
          headers: _headers,
        );
        print('✅ Backend health check passed: ${healthResponse.statusCode}');
      } catch (e) {
        print('❌ Backend health check failed: $e');
        return {'error': 'Backend not accessible'};
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.nutritionBaseUrl}/nutrition/analyze-with-gpt4'),
        headers: _headers,
        body: json.encode({
          'food_input': foodInput,
          'pregnancy_week': pregnancyWeek,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ GPT-4 analysis successful: ${result['success']}');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get GPT-4 analysis history (Food Entries)
  Future<Map<String, dynamic>> getGPT4AnalysisHistory(String userId) async {
    try {
      print('🔍 Getting food entries for user: $userId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/nutrition/get-food-entries/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Food entries retrieved: ${result['total_entries'] ?? 0} entries');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get mental health history
  Future<Map<String, dynamic>> getMentalHealthHistory(String patientId) async {
    try {
      print('🧠 Getting mental health history for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mental-health/history/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Mental health history retrieved: ${result['data']?['total_mood_entries'] ?? 0} mood entries');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get prescription documents
  Future<Map<String, dynamic>> getPrescriptionDocuments(String patientId) async {
    try {
      print('📋 Getting prescription documents for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/prescription/documents/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Prescription documents retrieved: ${result['totalDocuments'] ?? 0} documents');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get vital signs history
  Future<Map<String, dynamic>> getVitalSignsHistory(String patientId) async {
    try {
      print('💓 Getting vital signs history for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vital-signs/history/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Vital signs history retrieved: ${result['totalEntries'] ?? 0} entries');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Get kick count history
  Future<Map<String, dynamic>> getKickCountHistory(String patientId) async {
    try {
      print('🦵 Getting kick count history for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kick-count/get-kick-history/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Kick count history retrieved: ${result['total_entries'] ?? 0} entries');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Save kick count log
  Future<Map<String, dynamic>> saveKickCountLog(Map<String, dynamic> kickData) async {
    try {
      print('🦵 Saving kick count log: $kickData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/kick-count/save-kick-log'),
        headers: _headers,
        body: json.encode(kickData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Kick count log saved successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Transcribe audio using Whisper AI
  Future<Map<String, dynamic>> transcribeAudio(String audioBase64, {String language = 'auto'}) async {
    try {
      print('🎤 Transcribing audio with language: $language');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.nutritionBaseUrl}/nutrition/transcribe'),
        headers: _headers,
        body: json.encode({
          'audio': audioBase64,
          'language': language,
          'method': 'whisper'
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Audio transcription successful: ${result['success']}');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
} 
  }

  Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    try {
      print('🔍 API Service - getDoctorProfile:');
      print('  Doctor ID: $doctorId');
      print('  URL: ${ApiConfig.baseUrl}/doctor/profile/$doctorId');
      print('  Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/profile/$doctorId'),
        headers: _headers,
      );

      print('🔍 API Service - getDoctorProfile Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('🔍 API Service - getDoctorProfile Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateDoctorProfile({
    required String doctorId,
    required String firstName,
    required String lastName,
    required String specialization,
    required String licenseNumber,
    required int experienceYears,
    required String hospitalName,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required int consultationFee,
    required String profileUrl,
  }) async {
    try {
      final requestData = {
        'first_name': firstName,
        'last_name': lastName,
        'specialization': specialization,
        'license_number': licenseNumber,
        'experience_years': experienceYears,
        'hospital_name': hospitalName,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'consultation_fee': consultationFee,
        'profile_url': profileUrl,
      };
      
      print('🔍 API Service - updateDoctorProfile:');
      print('  URL: ${ApiConfig.baseUrl}/doctor/profile/$doctorId');
      print('  Headers: $_headers');
      print('  Request Data: ${json.encode(requestData)}');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctor/profile/$doctorId'),
        headers: _headers,
        body: json.encode(requestData),
      );

      print('🔍 API Service - updateDoctorProfile Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('🔍 API Service - updateDoctorProfile Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String role,
  }) async {
    try {
      print('🔍 API Service - resendOtp:');
      print('  Email: $email');
      print('  Role: $role');
      
      final requestData = {
        'email': email,
        'role': role,
      };
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/resend-otp'),
        headers: _headers,
        body: json.encode(requestData),
      );

      print('🔍 API Service - resendOtp Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('🔍 API Service - resendOtp Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Doctor Send OTP method
  Future<Map<String, dynamic>> doctorSendOtp({
    required String email,
    String purpose = 'signup',
  }) async {
    try {
      print('🔍 API Service - doctorSendOtp:');
      print('  Email: $email');
      print('  Purpose: $purpose');
      
      final requestData = {
        'email': email,
        'purpose': purpose,
      };
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctor-send-otp'),
        headers: _headers,
        body: json.encode(requestData),
      );

      print('🔍 API Service - doctorSendOtp Response:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('🔍 API Service - doctorSendOtp Error: $e');
      return {'error': 'Network error: $e'};
} 
  }

  /// Get complete patient details with all health data in one call
  Future<Map<String, dynamic>> getPatientFullDetails(String patientId) async {
    try {
      print('🔍 Getting FULL patient details for: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patient/$patientId/full-details'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Full patient details retrieved successfully');
        print('📊 Summary: ${result['summary']}');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientAISummary(String patientId) async {
    try {
      print('🤖 Getting AI summary for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patient/$patientId/ai-summary'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ AI summary retrieved successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Voice Dictation Methods
  Future<Map<String, dynamic>> createVoiceConversation(Map<String, dynamic> conversationData) async {
    try {
      print('🎤 Creating voice conversation...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/voice/conversations'),
        headers: _headers,
        body: json.encode(conversationData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Voice conversation created successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getVoiceConversation(String conversationId) async {
    try {
      print('🎤 Getting voice conversation: $conversationId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/voice/conversations/$conversationId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Voice conversation retrieved successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientVoiceConversations(String patientId) async {
    try {
      print('🎤 Getting voice conversations for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/voice/conversations/patient/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient voice conversations retrieved successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createVoiceTranscription(Map<String, dynamic> transcriptionData) async {
    try {
      print('🎤 Creating voice transcription...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/voice/transcriptions'),
        headers: _headers,
        body: json.encode(transcriptionData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Voice transcription created successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getConversationTranscriptions(String conversationId) async {
    try {
      print('🎤 Getting transcriptions for conversation: $conversationId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/voice/transcriptions/conversation/$conversationId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Conversation transcriptions retrieved successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> processAudioChunk({
    required String conversationId,
    required int chunkIndex,
    required String audioData,
  }) async {
    try {
      print('🎤 Processing audio chunk $chunkIndex for conversation: $conversationId');
      
      final requestData = {
        'conversation_id': conversationId,
        'chunk_index': chunkIndex,
        'audio_data': audioData,
      };
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/voice/process-audio'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Audio chunk processed successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getConversationSummary(String conversationId) async {
    try {
      print('🎤 Getting conversation summary: $conversationId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/voice/conversations/$conversationId/summary'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Conversation summary retrieved successfully');
        return result;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getConversationStatus(String conversationId) async {
    try {
      print('🎤 Getting conversation status for: $conversationId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/voice/conversations/$conversationId/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Conversation status retrieved successfully');
        return result;
      } else {
        print('❌ Get conversation status failed: ${response.statusCode}');
        return {'error': 'Failed to get conversation status: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get conversation status error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Patient CRUD Operations
  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    try {
      print('👤 Creating new patient...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/patients'),
        headers: _headers,
        body: json.encode(patientData),
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Patient created successfully');
        return result;
      } else {
        print('❌ Create patient failed: ${response.statusCode}');
        return {'error': 'Failed to create patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Create patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAllPatients({int page = 1, int limit = 20, String search = ''}) async {
    try {
      print('👤 Getting all patients...');
      
      String url = '${ApiConfig.baseUrl}/patients?page=$page&limit=$limit';
      if (search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patients retrieved successfully');
        return result;
      } else {
        print('❌ Get patients failed: ${response.statusCode}');
        return {'error': 'Failed to get patients: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get patients error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatient(String patientId) async {
    try {
      print('👤 Getting patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient retrieved successfully');
        return result;
      } else {
        print('❌ Get patient failed: ${response.statusCode}');
        return {'error': 'Failed to get patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePatient(String patientId, Map<String, dynamic> patientData) async {
    try {
      print('👤 Updating patient: $patientId');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
        body: json.encode(patientData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient updated successfully');
        return result;
      } else {
        print('❌ Update patient failed: ${response.statusCode}');
        return {'error': 'Failed to update patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Update patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePatient(String patientId) async {
    try {
      print('👤 Deleting patient: $patientId');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient deleted successfully');
        return result;
      } else {
        print('❌ Delete patient failed: ${response.statusCode}');
        return {'error': 'Failed to delete patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Delete patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientsByDoctor(String doctorId) async {
    try {
      print('👤 Getting patients for doctor: $doctorId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId/patients'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor patients retrieved successfully');
        return result;
      } else {
        print('❌ Get doctor patients failed: ${response.statusCode}');
        return {'error': 'Failed to get doctor patients: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get doctor patients error: $e');
      return {'error': 'Network error: $e'};
    }
  }
} 
  }

  Future<Map<String, dynamic>> getConversationStatus(String conversationId) async {
    try {
      print('🎤 Getting conversation status for: $conversationId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/voice/conversations/$conversationId/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Conversation status retrieved successfully');
        return result;
      } else {
        print('❌ Get conversation status failed: ${response.statusCode}');
        return {'error': 'Failed to get conversation status: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get conversation status error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Patient CRUD Operations
  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    try {
      print('👤 Creating new patient...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/patients'),
        headers: _headers,
        body: json.encode(patientData),
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Patient created successfully');
        return result;
      } else {
        print('❌ Create patient failed: ${response.statusCode}');
        return {'error': 'Failed to create patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Create patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAllPatients({int page = 1, int limit = 20, String search = ''}) async {
    try {
      print('👤 Getting all patients...');
      
      String url = '${ApiConfig.baseUrl}/patients?page=$page&limit=$limit';
      if (search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patients retrieved successfully');
        return result;
      } else {
        print('❌ Get patients failed: ${response.statusCode}');
        return {'error': 'Failed to get patients: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get patients error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatient(String patientId) async {
    try {
      print('👤 Getting patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient retrieved successfully');
        return result;
      } else {
        print('❌ Get patient failed: ${response.statusCode}');
        return {'error': 'Failed to get patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePatient(String patientId, Map<String, dynamic> patientData) async {
    try {
      print('👤 Updating patient: $patientId');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
        body: json.encode(patientData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient updated successfully');
        return result;
      } else {
        print('❌ Update patient failed: ${response.statusCode}');
        return {'error': 'Failed to update patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Update patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePatient(String patientId) async {
    try {
      print('👤 Deleting patient: $patientId');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient deleted successfully');
        return result;
      } else {
        print('❌ Delete patient failed: ${response.statusCode}');
        return {'error': 'Failed to delete patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Delete patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientsByDoctor(String doctorId) async {
    try {
      print('👤 Getting patients for doctor: $doctorId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId/patients'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor patients retrieved successfully');
        return result;
      } else {
        print('❌ Get doctor patients failed: ${response.statusCode}');
        return {'error': 'Failed to get doctor patients: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get doctor patients error: $e');
      return {'error': 'Network error: $e'};
    }
  }
} 
  }

  Future<Map<String, dynamic>> getConversationStatus(String conversationId) async {
    try {
      print('🎤 Getting conversation status for: $conversationId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/voice/conversations/$conversationId/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Conversation status retrieved successfully');
        return result;
      } else {
        print('❌ Get conversation status failed: ${response.statusCode}');
        return {'error': 'Failed to get conversation status: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get conversation status error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Patient CRUD Operations
  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> patientData) async {
    try {
      print('👤 Creating new patient...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/patients'),
        headers: _headers,
        body: json.encode(patientData),
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Patient created successfully');
        return result;
      } else {
        print('❌ Create patient failed: ${response.statusCode}');
        return {'error': 'Failed to create patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Create patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAllPatients({int page = 1, int limit = 20, String search = ''}) async {
    try {
      print('👤 Getting all patients...');
      
      String url = '${ApiConfig.baseUrl}/patients?page=$page&limit=$limit';
      if (search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patients retrieved successfully');
        return result;
      } else {
        print('❌ Get patients failed: ${response.statusCode}');
        return {'error': 'Failed to get patients: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get patients error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatient(String patientId) async {
    try {
      print('👤 Getting patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient retrieved successfully');
        return result;
      } else {
        print('❌ Get patient failed: ${response.statusCode}');
        return {'error': 'Failed to get patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePatient(String patientId, Map<String, dynamic> patientData) async {
    try {
      print('👤 Updating patient: $patientId');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
        body: json.encode(patientData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient updated successfully');
        return result;
      } else {
        print('❌ Update patient failed: ${response.statusCode}');
        return {'error': 'Failed to update patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Update patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePatient(String patientId) async {
    try {
      print('👤 Deleting patient: $patientId');
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient deleted successfully');
        return result;
      } else {
        print('❌ Delete patient failed: ${response.statusCode}');
        return {'error': 'Failed to delete patient: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Delete patient error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientsByDoctor(String doctorId) async {
    try {
      print('👤 Getting patients for doctor: $doctorId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId/patients'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor patients retrieved successfully');
        return result;
      } else {
        print('❌ Get doctor patients failed: ${response.statusCode}');
        return {'error': 'Failed to get doctor patients: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get doctor patients error: $e');
      return {'error': 'Network error: $e'};
    }
  }
} 