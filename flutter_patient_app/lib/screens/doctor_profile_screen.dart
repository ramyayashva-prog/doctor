import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _profileUrlController = TextEditingController();

  // Profile data
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _specializationController.dispose();
    _licenseNumberController.dispose();
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

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      
      final response = await apiService.getDoctorProfile(authProvider.patientId!);
      
      if (response['success'] == true) {
        setState(() {
          _profileData = response['doctor'];
          _populateFormFields();
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load profile';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormFields() {
    if (_profileData != null) {
      _firstNameController.text = _profileData!['first_name'] ?? '';
      _lastNameController.text = _profileData!['last_name'] ?? '';
      _specializationController.text = _profileData!['specialization'] ?? '';
      _licenseNumberController.text = _profileData!['license_number'] ?? '';
      _experienceController.text = _profileData!['experience_years']?.toString() ?? '';
      _hospitalController.text = _profileData!['hospital_name'] ?? '';
      _addressController.text = _profileData!['address'] ?? '';
      _cityController.text = _profileData!['city'] ?? '';
      _stateController.text = _profileData!['state'] ?? '';
      _pincodeController.text = _profileData!['pincode'] ?? '';
      _consultationFeeController.text = _profileData!['consultation_fee']?.toString() ?? '';
      _profileUrlController.text = _profileData!['profile_url'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      
      final response = await apiService.updateDoctorProfile(
        doctorId: authProvider.patientId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        specialization: _specializationController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
        hospitalName: _hospitalController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        consultationFee: int.tryParse(_consultationFeeController.text.trim()) ?? 0,
        profileUrl: _profileUrlController.text.trim(),
      );
      
      if (response['success'] == true) {
        setState(() {
          _isEditing = false;
          _profileData = response['doctor'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error updating profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _profileData == null
                  ? const Center(child: Text('No profile data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
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
                                      '${_profileData!['first_name']?[0] ?? ''}${_profileData!['last_name']?[0] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${_profileData!['first_name'] ?? ''} ${_profileData!['last_name'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _profileData!['specialization'] ?? 'Specialist',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ID: ${_profileData!['doctor_id'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  if (_profileData!['profile_url'] != null && _profileData!['profile_url'].isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        // TODO: Open profile URL in browser
        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Profile URL: ${_profileData!['profile_url']}'),
                                            backgroundColor: AppColors.info,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                              ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                children: [
                                            const Icon(
                                              Icons.link,
                                              size: 16,
                                      color: Colors.white70,
                                    ),
                                            const SizedBox(width: 4),
                                  Text(
                                              'View Profile',
                                    style: const TextStyle(
                                                fontSize: 12,
                                      color: Colors.white70,
                                                decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                                  ),
                                ),
                              ],
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
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'First name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _lastNameController,
                                    label: 'Last Name',
                                    enabled: _isEditing,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Last name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _specializationController,
                              label: 'Specialization',
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Specialization is required';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _licenseNumberController,
                              label: 'License Number',
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'License number is required';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _experienceController,
                              label: 'Experience (Years)',
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Experience is required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
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
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid amount';
                                  }
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _profileUrlController,
                              label: 'Profile URL',
                              enabled: _isEditing,
                              keyboardType: TextInputType.url,
                              hintText: 'https://example.com/profile',
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!Uri.tryParse(value)?.hasAbsolutePath ?? true) {
                                    return 'Please enter a valid URL';
                                  }
                                }
                                return null;
                              },
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
                                          _populateFormFields(); // Reset to original values
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _updateProfile,
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
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
