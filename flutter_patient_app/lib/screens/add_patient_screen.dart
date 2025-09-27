import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactNumberController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  String? _selectedGender;
  String? _selectedBloodType;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _medicalNotesController.dispose();
    _allergiesController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // 20 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patientData = {
        'full_name': _fullNameController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'gender': _selectedGender ?? '',
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'emergency_contact_name': _emergencyContactNameController.text.trim(),
        'emergency_contact_number': _emergencyContactNumberController.text.trim(),
        'medical_notes': _medicalNotesController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'blood_type': _selectedBloodType ?? '',
        'assigned_doctor_id': '', // Will be assigned by admin
        'is_active': true,
      };

      final response = await _apiService.createPatient(patientData);

      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
        });
        _showErrorSnackBar('Error creating patient: ${response['error']}');
      } else {
        _showSuccessSnackBar('Patient created successfully!');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
      _showErrorSnackBar('Network error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'e.g., John Doe',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: _dateOfBirthController,
                          label: 'Date of Birth',
                          hint: 'MM / DD / YYYY',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select date of birth';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genderOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Contact Details Section
              _buildSectionHeader('Contact Details'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      hint: 'e.g., (555) 123-4567',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact number';
                        }
                        if (value.length < 10) {
                          return 'Contact number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'e.g., john.doe@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter full address',
                      maxLines: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter city',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State',
                            hint: 'Enter state',
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'Enter pincode',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                      hint: 'Enter emergency contact name',
                    ),
                    _buildTextField(
                      controller: _emergencyContactNumberController,
                      label: 'Emergency Contact Number',
                      hint: 'Enter emergency contact number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              // Medical History Section
              _buildSectionHeader('Medical History'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _medicalNotesController,
                      label: 'Medical Notes',
                      hint: 'Enter any relevant medical notes, allergies, or conditions',
                      maxLines: 3,
                    ),
                    _buildTextField(
                      controller: _allergiesController,
                      label: 'Allergies',
                      hint: 'Enter any known allergies',
                      maxLines: 2,
                    ),
                    _buildDropdown(
                      label: 'Blood Type',
                      value: _selectedBloodType,
                      items: _bloodTypeOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Error Display
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Submit Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Patient',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import '../utils/constants.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactNumberController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  String? _selectedGender;
  String? _selectedBloodType;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _medicalNotesController.dispose();
    _allergiesController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // 20 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patientData = {
        'full_name': _fullNameController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'gender': _selectedGender ?? '',
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'emergency_contact_name': _emergencyContactNameController.text.trim(),
        'emergency_contact_number': _emergencyContactNumberController.text.trim(),
        'medical_notes': _medicalNotesController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'blood_type': _selectedBloodType ?? '',
        'assigned_doctor_id': '', // Will be assigned by admin
        'is_active': true,
      };

      final response = await _apiService.createPatient(patientData);

      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
        });
        _showErrorSnackBar('Error creating patient: ${response['error']}');
      } else {
        _showSuccessSnackBar('Patient created successfully!');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
      _showErrorSnackBar('Network error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'e.g., John Doe',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: _dateOfBirthController,
                          label: 'Date of Birth',
                          hint: 'MM / DD / YYYY',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select date of birth';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genderOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Contact Details Section
              _buildSectionHeader('Contact Details'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      hint: 'e.g., (555) 123-4567',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact number';
                        }
                        if (value.length < 10) {
                          return 'Contact number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'e.g., john.doe@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter full address',
                      maxLines: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter city',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State',
                            hint: 'Enter state',
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'Enter pincode',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                      hint: 'Enter emergency contact name',
                    ),
                    _buildTextField(
                      controller: _emergencyContactNumberController,
                      label: 'Emergency Contact Number',
                      hint: 'Enter emergency contact number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              // Medical History Section
              _buildSectionHeader('Medical History'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _medicalNotesController,
                      label: 'Medical Notes',
                      hint: 'Enter any relevant medical notes, allergies, or conditions',
                      maxLines: 3,
                    ),
                    _buildTextField(
                      controller: _allergiesController,
                      label: 'Allergies',
                      hint: 'Enter any known allergies',
                      maxLines: 2,
                    ),
                    _buildDropdown(
                      label: 'Blood Type',
                      value: _selectedBloodType,
                      items: _bloodTypeOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Error Display
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Submit Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Patient',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

import '../utils/constants.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactNumberController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  String? _selectedGender;
  String? _selectedBloodType;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _medicalNotesController.dispose();
    _allergiesController.dispose();
    _bloodTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // 20 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final patientData = {
        'full_name': _fullNameController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'gender': _selectedGender ?? '',
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'emergency_contact_name': _emergencyContactNameController.text.trim(),
        'emergency_contact_number': _emergencyContactNumberController.text.trim(),
        'medical_notes': _medicalNotesController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'blood_type': _selectedBloodType ?? '',
        'assigned_doctor_id': '', // Will be assigned by admin
        'is_active': true,
      };

      final response = await _apiService.createPatient(patientData);

      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
        });
        _showErrorSnackBar('Error creating patient: ${response['error']}');
      } else {
        _showSuccessSnackBar('Patient created successfully!');
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
      _showErrorSnackBar('Network error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'e.g., John Doe',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: _dateOfBirthController,
                          label: 'Date of Birth',
                          hint: 'MM / DD / YYYY',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select date of birth';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genderOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Contact Details Section
              _buildSectionHeader('Contact Details'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      hint: 'e.g., (555) 123-4567',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact number';
                        }
                        if (value.length < 10) {
                          return 'Contact number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'e.g., john.doe@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter full address',
                      maxLines: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            hint: 'Enter city',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State',
                            hint: 'Enter state',
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      hint: 'Enter pincode',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                      hint: 'Enter emergency contact name',
                    ),
                    _buildTextField(
                      controller: _emergencyContactNumberController,
                      label: 'Emergency Contact Number',
                      hint: 'Enter emergency contact number',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),

              // Medical History Section
              _buildSectionHeader('Medical History'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _medicalNotesController,
                      label: 'Medical Notes',
                      hint: 'Enter any relevant medical notes, allergies, or conditions',
                      maxLines: 3,
                    ),
                    _buildTextField(
                      controller: _allergiesController,
                      label: 'Allergies',
                      hint: 'Enter any known allergies',
                      maxLines: 2,
                    ),
                    _buildDropdown(
                      label: 'Blood Type',
                      value: _selectedBloodType,
                      items: _bloodTypeOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Error Display
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Submit Button
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Patient',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
