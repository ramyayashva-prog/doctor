import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class SimpleDoctorProfileScreen extends StatefulWidget {
  const SimpleDoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<SimpleDoctorProfileScreen> createState() => _SimpleDoctorProfileScreenState();
}

class _SimpleDoctorProfileScreenState extends State<SimpleDoctorProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _error;
  Map<String, dynamic>? _profileData;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _profileUrlController = TextEditingController();

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    print('🔍 SimpleDoctorProfileScreen initState called');
    // Add a small delay to ensure AuthProvider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔍 PostFrameCallback triggered - calling _loadProfileFromBackend');
      _loadProfileFromBackend();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _consultationFeeController.dispose();
    _profileUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileFromBackend() async {
    try {
      setState(() {
        _isLoadingProfile = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorId = authProvider.patientId; // Doctor ID is stored in patientId field

      print('🔍 Profile Screen Debug:');
      print('  AuthProvider.patientId: $doctorId');
      print('  AuthProvider.isLoggedIn: ${authProvider.isLoggedIn}');
      print('  AuthProvider.email: ${authProvider.email}');
      print('  AuthProvider.role: ${authProvider.role}');

      if (doctorId == null || doctorId.isEmpty) {
        print('❌ Doctor ID is null or empty, trying to get from SharedPreferences...');
        
        // Try to get doctor ID from SharedPreferences as fallback
        final prefs = await SharedPreferences.getInstance();
        final savedDoctorId = prefs.getString('patientId');
        
        if (savedDoctorId != null && savedDoctorId.isNotEmpty) {
          print('✅ Found doctor ID in SharedPreferences: $savedDoctorId');
          await _loadProfileWithId(savedDoctorId);
          return;
        } else {
          setState(() {
            _error = 'Doctor ID not found. Please login again.';
            _isLoadingProfile = false;
          });
          print('❌ No doctor ID found in SharedPreferences either');
          return;
        }
      }

      print('🔍 Loading profile for doctor ID: $doctorId');
      await _loadProfileWithId(doctorId);
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() {
        _error = 'Network error: $e';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadProfileWithId(String doctorId) async {
    try {
      print('🔍 Loading profile with ID: $doctorId');
      
      final response = await _apiService.getDoctorProfile(doctorId);
      
      print('🔍 Profile response: $response');

      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
          _isLoadingProfile = false;
        });
        return;
      }

      if (response['success'] == true && response['doctor'] != null) {
        final doctor = response['doctor'];
        setState(() {
          _profileData = doctor;
          _isLoadingProfile = false;
        });
        
        // Populate form fields with real data
        _populateFormFields(doctor);
      } else {
        setState(() {
          _error = 'Failed to load profile data';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      setState(() {
        _error = 'Network error: $e';
        _isLoadingProfile = false;
      });
    }
  }

  void _populateFormFields(Map<String, dynamic> doctor) {
    _firstNameController.text = doctor['first_name'] ?? '';
    _lastNameController.text = doctor['last_name'] ?? '';
    _specializationController.text = doctor['specialization'] ?? '';
    _licenseController.text = doctor['license_number'] ?? '';
    _experienceController.text = (doctor['experience_years'] ?? 0).toString();
    _hospitalController.text = doctor['hospital_name'] ?? '';
    _addressController.text = doctor['address'] ?? '';
    _cityController.text = doctor['city'] ?? '';
    _stateController.text = doctor['state'] ?? '';
    _pincodeController.text = doctor['pincode'] ?? '';
    _consultationFeeController.text = (doctor['consultation_fee'] ?? 0).toString();
    _profileUrlController.text = doctor['profile_url'] ?? '';
  }

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (firstName.isEmpty && lastName.isEmpty) {
      return 'DR';
    }
    
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    
    return initials;
  }

  String _getFullName() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    if (firstName.isEmpty && lastName.isEmpty) {
      return 'Dr. Unknown';
    }
    
    String name = '';
    if (firstName.isNotEmpty) {
      name += firstName.startsWith('Dr.') ? firstName : 'Dr. $firstName';
    }
    if (lastName.isNotEmpty) {
      name += ' $lastName';
    }
    
    return name;
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorId = authProvider.patientId; // Doctor ID is stored in patientId field

      if (doctorId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor ID not found. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('🔍 Saving profile for doctor ID: $doctorId');
      
      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'hospitalName': _hospitalController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'consultationFee': int.tryParse(_consultationFeeController.text) ?? 0,
        'profileUrl': _profileUrlController.text.trim(),
      };
      
      final response = await _apiService.updateDoctorProfile(doctorId, profileData);
      
      print('🔍 Update response: $response');

      setState(() {
        _isLoading = false;
      });

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response['success'] == true) {
        setState(() {
          _isEditing = false;
        });
        
        // Update profile data
        if (response['doctor'] != null) {
          _profileData = response['doctor'];
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              _loadProfileFromBackend();
            },
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              print('🐛 Debug: Forcing profile load with hardcoded ID');
              _loadProfileWithId('D17587987732214');
            },
            tooltip: 'Debug Load Profile',
          ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfileFromBackend,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            _getInitials(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getFullName(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _specializationController.text.isNotEmpty 
                              ? _specializationController.text 
                              : 'Specialization not set',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${_profileData?['doctor_id'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Personal Information
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          enabled: _isEditing,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          enabled: _isEditing,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _specializationController,
                    label: 'Specialization',
                    enabled: _isEditing,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _licenseController,
                    label: 'License Number',
                    enabled: _isEditing,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _experienceController,
                    label: 'Experience (Years)',
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Professional Information
                  _buildSectionHeader('Professional Information'),
                  const SizedBox(height: 12),
                  
                  _buildTextField(
                    controller: _hospitalController,
                    label: 'Hospital/Clinic Name',
                    enabled: _isEditing,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _consultationFeeController,
                    label: 'Consultation Fee (₹)',
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                  
                  _buildTextField(
                    controller: _profileUrlController,
                    label: 'Profile URL',
                    enabled: _isEditing,
                    keyboardType: TextInputType.url,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contact Information
                  _buildSectionHeader('Contact Information'),
                  const SizedBox(height: 12),
                  
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    enabled: _isEditing,
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'City',
                          enabled: _isEditing,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _stateController,
                          label: 'State',
                          enabled: _isEditing,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _loadProfileFromBackend(); // Reset to original values
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
    );
  }
}