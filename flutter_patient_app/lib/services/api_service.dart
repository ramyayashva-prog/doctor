import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static String? _authToken;

  static Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    return headers;
  }

  // Initialize auth token from storage
  static Future<void> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Set auth token
  static Future<void> setAuthToken(String token, String patientId, String doctorId) async {
    _authToken = token;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('patient_id', patientId);
    await prefs.setString('doctor_id', doctorId);
  }

  // Clear auth token
  static Future<void> clearAuth() async {
    _authToken = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('patient_id');
    await prefs.remove('doctor_id');
  }

  Map<String, String> _getAuthHeaders() {
    final headers = Map<String, String>.from(_headers);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Health Check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      print('🏥 Checking server health...');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Server is healthy');
        return result;
      } else {
        print('❌ Health check failed: ${response.statusCode}');
        return {'error': 'Health check failed: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Health check error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Authentication Methods
  Future<Map<String, dynamic>> login(Map<String, dynamic> loginData) async {
    try {
      print('🔐 Attempting login...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: _headers,
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Login successful');
        
        // Store auth token if provided
        if (result['token'] != null) {
          await setAuthToken(
            result['token'], 
            result['patient_id'] ?? result['doctor_id'] ?? '', 
            result['doctor_id'] ?? ''
          );
        }
        
        return result;
      } else {
        print('❌ Login failed: ${response.statusCode}');
        return {'error': 'Login failed: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> doctorLogin(Map<String, dynamic> loginData) async {
    try {
      print('👨‍⚕️ Attempting doctor login...');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctor-login'),
        headers: _headers,
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor login successful');
        
        // Store auth token if provided
        if (result['token'] != null) {
          await setAuthToken(
            result['token'], 
            result['doctor_id'] ?? '', 
            result['doctor_id'] ?? ''
          );
        }
        
        return result;
      } else {
        print('❌ Doctor login failed: ${response.statusCode}');
        return {'error': 'Doctor login failed: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Doctor login error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Patient CRUD Methods
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

  Future<Map<String, dynamic>> getAllPatients({int page = 1, int limit = 20, String search = ''}) async {
    try {
      print('👥 Getting all patients...');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/patients').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (search.isNotEmpty) 'search': search,
        },
      );
      
      final response = await http.get(
        uri,
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

  // Doctor Methods

  Future<Map<String, dynamic>> getDoctorDashboard(String doctorId) async {
    try {
      print('📊 Getting doctor dashboard: $doctorId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/$doctorId/dashboard'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor dashboard retrieved successfully');
        return result;
      } else {
        print('❌ Get doctor dashboard failed: ${response.statusCode}');
        return {'error': 'Failed to get doctor dashboard: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get doctor dashboard error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientFullDetails(String patientId) async {
    try {
      print('👤 Getting full patient details: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patient/$patientId/full-details'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Patient full details retrieved successfully');
        return result;
      } else {
        print('❌ Get patient full details failed: ${response.statusCode}');
        return {'error': 'Failed to get patient details: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get patient full details error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientAISummary(String patientId) async {
    try {
      print('🤖 Getting AI summary for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patient/$patientId/ai-summary'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ AI summary retrieved successfully');
        return result;
      } else {
        print('❌ Get AI summary failed: ${response.statusCode}');
        return {'error': 'Failed to get AI summary: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Get AI summary error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getDoctorPatients(String doctorId) async {
    try {
      print('👥 Getting patients for doctor: $doctorId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/$doctorId/patients'),
        headers: _getAuthHeaders(),
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

  // Additional missing methods
  static Future<void> clearAuthToken() async {
    await clearAuth();
  }

  Future<Map<String, dynamic>> verifyToken({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Token verification failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> signupData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/signup'),
        headers: _headers,
        body: json.encode(signupData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'error': 'Signup failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(Map<String, dynamic> otpData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/verify-otp'),
        headers: _headers,
        body: json.encode(otpData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'OTP verification failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/forgot-password'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Forgot password failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reset-password'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Password reset failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resendOtp(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/resend-otp'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Resend OTP failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> doctorSendOtp(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctor-send-otp'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Doctor OTP send failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> completeProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/complete-profile'),
        headers: _getAuthHeaders(),
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Profile completion failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProfile({required String patientId}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get profile failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveKickSession(Map<String, dynamic> kickData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/kick-count/save-session'),
        headers: _getAuthHeaders(),
        body: json.encode(kickData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'error': 'Save kick session failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getKickHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kick-count/get-kick-history/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get kick history failed'};
      }
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get dashboard stats failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> saveTabletTracking(Map<String, dynamic> tabletData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/save-tablet-tracking'),
        headers: _getAuthHeaders(),
        body: json.encode(tabletData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'error': 'Save tablet tracking failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientDetails(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patient/$patientId/details'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get patient details failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAppointments({String? patientId, String? doctorId}) async {
    try {
      String url = '${ApiConfig.baseUrl}/doctor/appointments';
      if (patientId != null) {
        url += '?patient_id=$patientId';
      } else if (doctorId != null) {
        url += '?doctor_id=$doctorId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get appointments failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMedicationHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medication/get-medication-history/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get medication history failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getSymptomAnalysisReports(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/symptoms/get-analysis-reports/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get symptom analysis reports failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getGPT4AnalysisHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/gpt4/get-analysis-history/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get GPT4 analysis history failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getTabletTrackingHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medication/get-tablet-tracking-history/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get tablet tracking history failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPrescriptionDetails(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/prescriptions/get-details/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get prescription details failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getKickCountHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kick-count/get-kick-history/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get kick count history failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getMentalHealthHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/mental-health/get-history/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get mental health history failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPrescriptionDocuments(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/prescriptions/get-documents/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get prescription documents failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getVitalSignsHistory(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vital-signs/get-history/$patientId'),
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Get vital signs history failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctor/appointments'),
        headers: _getAuthHeaders(),
        body: json.encode(appointmentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'error': 'Create appointment failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAppointment(String appointmentId, Map<String, dynamic> appointmentData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctor/appointments/$appointmentId'),
        headers: _getAuthHeaders(),
        body: json.encode(appointmentData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Update appointment failed'};
      }
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Delete appointment failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> completeDoctorProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/doctor/complete-profile'),
        headers: _getAuthHeaders(),
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Complete doctor profile failed'};
      }
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // Get upcoming medication dosages for a patient
  Future<Map<String, dynamic>> getUpcomingDosages(String patientId) async {
    try {
      print('💊 Getting upcoming dosages for patient: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patients/$patientId/upcoming-dosages'),
        headers: _getAuthHeaders(),
      );

      print('📡 Upcoming dosages response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Upcoming dosages data: ${json.encode(data)}');
        return data;
      } else {
        print('❌ Failed to get upcoming dosages: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to get upcoming dosages: ${response.statusCode}',
          'upcoming_dosages': [],
          'prescription_medications': [],
          'total_upcoming': 0,
          'total_prescriptions': 0,
          'current_time': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print('❌ Error getting upcoming dosages: $e');
      return {
        'success': false,
        'message': 'Error getting upcoming dosages: $e',
        'upcoming_dosages': [],
        'prescription_medications': [],
        'total_upcoming': 0,
        'total_prescriptions': 0,
        'current_time': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> saveMedicationLog(Map<String, dynamic> medicationData) async {
    try {
      print('💊 Saving medication log: ${json.encode(medicationData)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/medication/save-medication-log'),
        headers: _getAuthHeaders(),
        body: json.encode(medicationData),
      );

      print('📡 Save medication log response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Medication log saved successfully');
        return result;
      } else {
        print('❌ Save medication log failed: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to save medication log: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Save medication log error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> saveSleepLog(Map<String, dynamic> sleepData) async {
    try {
      print('😴 Saving sleep log: ${json.encode(sleepData)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/sleep/save-sleep-log'),
        headers: _getAuthHeaders(),
        body: json.encode(sleepData),
      );

      print('📡 Save sleep log response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Sleep log saved successfully');
        return result;
      } else {
        print('❌ Save sleep log failed: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to save sleep log: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Save sleep log error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get doctor profile by ID
  Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    try {
      print('👨‍⚕️ Getting doctor profile for ID: $doctorId');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/profile/$doctorId'),
        headers: _getAuthHeaders(),
      );

      print('📡 Get doctor profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor profile retrieved successfully');
        return result;
      } else {
        print('❌ Get doctor profile failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to get doctor profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Get doctor profile error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Update doctor profile
  Future<Map<String, dynamic>> updateDoctorProfile(String doctorId, Map<String, dynamic> profileData) async {
    try {
      print('👨‍⚕️ Updating doctor profile for ID: $doctorId');
      print('📝 Profile data: ${json.encode(profileData)}');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctor/profile/$doctorId'),
        headers: _getAuthHeaders(),
        body: json.encode(profileData),
      );

      print('📡 Update doctor profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor profile updated successfully');
        return result;
      } else {
        print('❌ Update doctor profile failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to update doctor profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Update doctor profile error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Analyze symptoms with AI
  Future<Map<String, dynamic>> analyzeSymptoms(Map<String, dynamic> symptomData) async {
    try {
      print('🤖 Analyzing symptoms: ${json.encode(symptomData)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/symptoms/analyze'),
        headers: _getAuthHeaders(),
        body: json.encode(symptomData),
      );

      print('📡 Analyze symptoms response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Symptoms analyzed successfully');
        return result;
      } else {
        print('❌ Analyze symptoms failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to analyze symptoms: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Analyze symptoms error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Save symptom analysis report
  Future<Map<String, dynamic>> saveSymptomAnalysisReport(Map<String, dynamic> reportData) async {
    try {
      print('📊 Saving symptom analysis report: ${json.encode(reportData)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/symptoms/save-analysis-report'),
        headers: _getAuthHeaders(),
        body: json.encode(reportData),
      );

      print('📡 Save symptom analysis report response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        print('✅ Symptom analysis report saved successfully');
        return result;
      } else {
        print('❌ Save symptom analysis report failed: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to save symptom analysis report: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Save symptom analysis report error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}