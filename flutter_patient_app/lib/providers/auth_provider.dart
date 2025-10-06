import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _patientId;
  String? _email;
  String? _username;
  String? _token;
  String? _error;
  String? _role;
  String? _objectId; // Add Object ID
  String? _jwtToken; // Store JWT token for OTP verification

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get patientId => _patientId;
  String? get email => _email;
  String? get username => _username;
  String? get token => _token;
  String? get error => _error;
  String? get role => _role;
  String? get jwtToken => _jwtToken;

  // Get current user information for data storage
  Future<Map<String, String?>> getCurrentUserInfo() async {
    try {
      // Ensure we have the latest data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _email = prefs.getString('email') ?? "";
      _username = prefs.getString('username') ?? "";
      _patientId = prefs.getString('patientId') ?? "";
      _role = prefs.getString('role') ?? "";
      _objectId = prefs.getString('objectId') ?? ""; // Add Object ID
      _jwtToken = prefs.getString('jwt_token');
      
      // Debug logging
      print('🔍 AuthProvider Debug - getCurrentUserInfo:');
      print('  Email: $_email');
      print('  Username: $_username');
      print('  PatientId: $_patientId');
      print('  Role: $_role');
      print('  ObjectId: $_objectId');
      
      // Validate that we have the minimum required data
      if ((_email?.isEmpty ?? true) || (_username?.isEmpty ?? true) || (_patientId?.isEmpty ?? true)) {
        print('⚠️  WARNING: Missing required user data in SharedPreferences');
        print('   This might cause null value errors in the dashboard');
        
        // Try to get from memory if SharedPreferences is empty
        if ((_email?.isEmpty ?? true) && (_username?.isNotEmpty ?? false) && (_patientId?.isNotEmpty ?? false)) {
          print('   Using in-memory data as fallback');
        }
      }
      
      return {
        'userId': (_patientId?.isNotEmpty ?? false) ? _patientId : null,
        'userRole': (_role?.isNotEmpty ?? false) ? _role : null,
        'username': (_username?.isNotEmpty ?? false) ? _username : null,
        'email': (_email?.isNotEmpty ?? false) ? _email : null,
        'objectId': (_objectId?.isNotEmpty ?? false) ? _objectId : null,
      };
    } catch (e) {
      print('❌ ERROR in getCurrentUserInfo: $e');
      // Return safe defaults instead of throwing
      return {
        'userId': null,
        'userRole': null,
        'username': null,
        'email': null,
        'objectId': null,
      };
    }
  }


  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _role = prefs.getString('role');
    
    if (_token != null) {
      // Verify token with patient server
      try {
        final response = await _apiService.verifyToken(token: _token!);
        
        if (response.containsKey('valid') && response['valid'] == true) {
          _isLoggedIn = true;
          _patientId = prefs.getString('patientId');
          _email = prefs.getString('email');
          _username = prefs.getString('username');
          
          // Set token in API service
          ApiService.setAuthToken(_token!, _patientId ?? '', _patientId ?? '');
        } else {
          // Token is invalid, clear everything
          await logout();
        }
      } catch (e) {
        print('❌ Token verification failed: $e');
        await logout();
      }
    } else {
      _isLoggedIn = false;
    }
    
    notifyListeners();
  }

  Future<bool> login({
    required String loginIdentifier,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    _role = role;
    notifyListeners();

    try {
      // Use appropriate login method based on role
      final response = role == 'doctor' 
        ? await _apiService.doctorLogin({
            'email': loginIdentifier, // Doctor login uses email
            'password': password,
          })
        : await _apiService.login({
        'loginIdentifier': loginIdentifier,
        'password': password,
        'role': role,
      });

      if (response.containsKey('error')) {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Handle both patient and doctor login responses
      bool hasValidResponse = false;
      
      if (role == 'doctor') {
        // Doctor login response has doctor_id and name
        print('🔍 AuthProvider - Doctor Login Response:');
        print('  doctor_id: ${response['doctor_id']}');
        print('  name: ${response['name']}');
        print('  email: ${response['email']}');
        print('  token: ${response['token'] != null ? 'Present' : 'Missing'}');
        
        if (response['doctor_id'] != null || response['email'] != null) {
          hasValidResponse = true;
          _isLoggedIn = true;
          _patientId = response['doctor_id'] ?? ""; // Store doctor_id in patientId field for consistency
          _email = response['email'] ?? "";
          _username = response['name'] ?? response['username'] ?? ""; // Doctors have 'name' field
          _token = response['token'] ?? "";
          _objectId = response['object_id'] ?? response['objectId'] ?? "";
          
          print('🔍 AuthProvider - Stored Values:');
          print('  _patientId (doctor_id): $_patientId');
          print('  _email: $_email');
          print('  _username: $_username');
          print('  _isLoggedIn: $_isLoggedIn');
        }
      } else {
        // Patient login response has patient_id
        if (response['patient_id'] != null) {
          hasValidResponse = true;
          _isLoggedIn = true;
          _patientId = response['patient_id'] ?? "";
          _email = response['email'] ?? "";
          _username = response['username'] ?? "";
          _token = response['token'] ?? "";
          _objectId = response['object_id'] ?? response['objectId'] ?? "";
        }
      }

      if (hasValidResponse) {
        // Debug logging to see what we received
        print('🔍 AuthProvider Debug - Login Response:');
        print('  role: $_role');
        print('  user_id: $_patientId');
        print('  email: $_email');
        print('  username: $_username');
        print('  token: $_token');
        print('  object_id: $_objectId');

        // Validate required fields
        if (_email!.isEmpty || _username!.isEmpty || _token!.isEmpty) {
          _error = 'Login response missing required fields';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('patientId', _patientId!); // Store user ID (patient_id or doctor_id)
        await prefs.setString('email', _email!);
        await prefs.setString('username', _username!);
        await prefs.setString('auth_token', _token!);
        await prefs.setString('role', _role!);
        await prefs.setString('objectId', _objectId ?? "");
        if (_jwtToken != null) {
          await prefs.setString('jwt_token', _jwtToken!);
        }

        // Debug logging for SharedPreferences
        print('🔍 AuthProvider Debug - SharedPreferences Saved:');
        print('  isLoggedIn: true');
        print('  userId: $_patientId');
        print('  email: $_email');
        print('  username: $_username');
        print('  token: $_token');
        print('  role: $_role');
        print('  objectId: $_objectId');
        print('  jwt_token: ${_jwtToken?.substring(0, 20) ?? 'None'}...');

        // Set token in API service
        ApiService.setAuthToken(_token!, _patientId ?? '', _patientId ?? '');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Login failed - missing user identification';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String username,
    required String email,
    required String mobile,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.signup({
        'username': username,
        'email': email,
        'mobile': mobile,
        'password': password,
        'role': role,
      });

      if (response.containsKey('error')) {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // NEW FLOW: Backend automatically sends OTP during signup
      print('🔍 AuthProvider - Signup Response:');
      print('  Role: $role');
      print('  Response keys: ${response.keys.toList()}');
      print('  Status: ${response['status']}');
      
      if (role == 'doctor' && response['status'] == 'otp_sent') {
        // Backend now automatically sends OTP during signup
        print('✅ AuthProvider - Doctor signup completed with automatic OTP');
        
        // Check if response contains signup_token (JWT token)
        if (response.containsKey('signup_token')) {
          // Store JWT token for OTP verification
          _jwtToken = response['signup_token'];
          await _storeJwtToken(_jwtToken!);
          print('✅ AuthProvider - Signup token received and stored');
          print('📧 OTP sent to: ${response['email']}');
          print('📧 Check your email for the OTP code');
        } else {
          print('❌ AuthProvider - No signup token received');
          _error = 'Failed to receive signup token';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (role == 'doctor') {
        print('⚠️ AuthProvider - Doctor signup completed but no OTP status found');
        print('📧 Response: $response');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    _role = role;
    notifyListeners();

    try {
      // Use regular ApiService for patient OTP verification
      print('🔍 AuthProvider - OTP Verification:');
      print('  Email: $email');
      print('  OTP: $otp');
      print('  Role: $role');
      print('  JWT Token: ${_jwtToken?.substring(0, 50) ?? 'None'}...');
      
      // CRITICAL: Validate JWT token for doctor role
      if (role == 'doctor') {
        if (_jwtToken == null || _jwtToken!.isEmpty) {
          print('❌ AuthProvider - JWT token is missing for doctor OTP verification');
          _error = 'JWT token is missing. Please try signing up again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        print('✅ AuthProvider - JWT token is present for doctor verification');
      }
      
      // Load JWT token from storage if not already loaded
      if (_jwtToken == null) {
        await _loadJwtToken();
      }
      
      // Debug logging for OTP verification
      print('🔍 AuthProvider - OTP Verification Debug:');
      print('  Email: $email');
      print('  OTP: $otp');
      print('  Role: $role');
      print('  JWT Token: ${_jwtToken?.substring(0, 50) ?? 'NULL'}...');
      print('  JWT Token Length: ${_jwtToken?.length ?? 0}');
      
      // Check if JWT token is available
      if (_jwtToken == null || _jwtToken!.isEmpty) {
        print('❌ AuthProvider - JWT token is null or empty');
        _error = 'JWT token not found. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final response = await _apiService.verifyOtp({
        'email': email,
        'otp': otp,
        'role': role,
        'jwt_token': _jwtToken, // Pass JWT token for doctor verification
      });

      if (response.containsKey('error')) {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Handle both patient and doctor OTP verification responses
      bool hasValidResponse = false;
      
      if (role == 'doctor') {
        // Doctor OTP verification response has doctor_id
        print('🔍 AuthProvider Debug - Doctor OTP Response:');
        print('  Response keys: ${response.keys.toList()}');
        print('  doctor_id: ${response['doctor_id']}');
        print('  success: ${response['success']}');
        print('  email: ${response['email']}');
        print('  username: ${response['username']}');
        print('  token: ${response['token']}');
        
        if (response['doctor_id'] != null || response['success'] == true) {
          hasValidResponse = true;
          _isLoggedIn = true;
          _patientId = response['doctor_id'] ?? ""; // Store doctor_id in patientId field for consistency
          _email = response['email'] ?? "";
          _username = response['username'] ?? "";
          _token = response['access_token'] ?? response['token'] ?? ""; // Use access_token if available
          _objectId = response['objectId'] ?? "";
          
          // Clear JWT token after successful verification
          _jwtToken = null;
          
          print('🔍 AuthProvider Debug - Stored values:');
          print('  _patientId (doctor_id): $_patientId');
          print('  _email: $_email');
          print('  _username: $_username');
          print('  _token: ${_token?.substring(0, 20)}...');
        }
      } else {
        // Patient OTP verification response has patient_id
        if (response['patient_id'] != null) {
          hasValidResponse = true;
          _isLoggedIn = true;
          _patientId = response['patient_id'] ?? "";
          _email = response['email'] ?? "";
          _username = response['username'] ?? "";
          _token = response['token'] ?? "";
          _objectId = response['objectId'] ?? "";
        }
      }

      if (hasValidResponse) {
        // Debug logging to see what we received
        print('🔍 AuthProvider Debug - OTP Verification Response:');
        print('  role: $_role');
        print('  user_id: $_patientId');
        print('  email: $_email');
        print('  username: $_username');
        print('  token: $_token');
        print('  object_id: $_objectId');

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('patientId', _patientId!);
        await prefs.setString('email', _email!);
        await prefs.setString('username', _username!);
        await prefs.setString('auth_token', _token!);
        await prefs.setString('role', _role!);
        await prefs.setString('objectId', _objectId!);

        // Set token in API service
        ApiService.setAuthToken(_token!, _patientId ?? '', _patientId ?? '');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'OTP verification failed - missing user identification';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword({
    required String loginIdentifier,
    String role = 'patient',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.forgotPassword({
        'loginIdentifier': loginIdentifier,
        'role': role,
      });

      if (response.containsKey('error')) {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    String role = 'patient',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.resetPassword({
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
        'role': role,
      });

      if (response.containsKey('error')) {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }



  Future<void> logout() async {
    _isLoggedIn = false;
    _patientId = null;
    _email = null;
    _username = null;
    _token = null;
    _error = null;
    _role = null;
    _objectId = null; // Clear Object ID on logout
    _jwtToken = null; // Clear JWT token on logout

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Clear token from API service
    ApiService.clearAuthToken();

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> resendOtp({
    required String email,
    required String role,
  }) async {
    try {
      print('🔍 AuthProvider - resendOtp:');
      print('  Email: $email');
      print('  Role: $role');
      
      final response = await _apiService.resendOtp({
        'email': email,
        'role': role,
      });
      
      print('🔍 AuthProvider - resendOtp Response:');
      print('  Response: $response');
      
      // Store JWT token if received (for doctor role)
      if (role == 'doctor' && response.containsKey('jwt_token') && response['jwt_token'] != null) {
        _jwtToken = response['jwt_token'];
        print('✅ AuthProvider - JWT token stored from resendOtp');
        print('  JWT token length: ${_jwtToken?.length}');
        print('  JWT token preview: ${_jwtToken?.substring(0, 50)}...');
      } else if (role == 'doctor') {
        print('⚠️ AuthProvider - No JWT token in resendOtp response');
      }
      
      return response;
    } catch (e) {
      print('❌ AuthProvider - resendOtp Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Doctor Send OTP method
  Future<Map<String, dynamic>> doctorSendOtp({
    required String email,
    String purpose = 'signup',
  }) async {
    try {
      print('🔍 AuthProvider - doctorSendOtp:');
      print('  Email: $email');
      print('  Purpose: $purpose');
      
      final response = await _apiService.doctorSendOtp({
        'email': email,
        'purpose': purpose,
      });
      
      print('🔍 AuthProvider - doctorSendOtp Response:');
      print('  Response: $response');
      
      // Store JWT token if received
      if (response.containsKey('jwt_token') && response['jwt_token'] != null) {
        _jwtToken = response['jwt_token'];
        print('✅ AuthProvider - JWT token stored from doctorSendOtp');
        print('  JWT token length: ${_jwtToken?.length}');
        print('  JWT token preview: ${_jwtToken?.substring(0, 50)}...');
      } else {
        print('⚠️ AuthProvider - No JWT token in doctorSendOtp response');
      }
      
      return response;
    } catch (e) {
      print('❌ AuthProvider - doctorSendOtp Error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  // Store JWT token
  Future<void> _storeJwtToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      _jwtToken = token;
      print('✅ AuthProvider - JWT token stored');
    } catch (e) {
      print('❌ AuthProvider - Store JWT token error: $e');
    }
  }

  // Load JWT token from SharedPreferences
  Future<void> _loadJwtToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        _jwtToken = token;
        print('✅ AuthProvider - JWT token loaded from storage');
        print('  JWT token length: ${_jwtToken?.length}');
      } else {
        print('⚠️ AuthProvider - No JWT token found in storage');
      }
    } catch (e) {
      print('❌ AuthProvider - Load JWT token error: $e');
    }
  }

  // Clear JWT token
  Future<void> _clearJwtToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      _jwtToken = null;
      print('✅ AuthProvider - JWT token cleared');
    } catch (e) {
      print('❌ AuthProvider - Clear JWT token error: $e');
    }
  }
} 