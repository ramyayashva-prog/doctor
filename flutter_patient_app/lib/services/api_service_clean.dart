import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static String? _authToken;
  static String? _patientId;
  static String? _doctorId;

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
    _patientId = prefs.getString('patient_id');
    _doctorId = prefs.getString('doctor_id');
  }

  // Set auth token
  static Future<void> setAuthToken(String token, String patientId, String doctorId) async {
    _authToken = token;
    _patientId = patientId;
    _doctorId = doctorId;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('patient_id', patientId);
    await prefs.setString('doctor_id', doctorId);
  }

  // Clear auth token
  static Future<void> clearAuth() async {
    _authToken = null;
    _patientId = null;
    _doctorId = null;
    
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
  Future<Map<String, dynamic>> updateDoctorProfile(String doctorId, Map<String, dynamic> profileData) async {
    try {
      print('👨‍⚕️ Updating doctor profile: $doctorId');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/doctor/$doctorId/profile'),
        headers: _getAuthHeaders(),
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Doctor profile updated successfully');
        return result;
      } else {
        print('❌ Update doctor profile failed: ${response.statusCode}');
        return {'error': 'Failed to update doctor profile: ${response.statusCode}'};
      }
    } catch (e) {
      print('❌ Update doctor profile error: $e');
      return {'error': 'Network error: $e'};
    }
  }

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

  // Voice Dictation Methods - REMOVED (voice functionality disabled)
}
