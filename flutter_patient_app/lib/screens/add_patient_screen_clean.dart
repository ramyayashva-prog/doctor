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
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
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
        'assigned_doctor_id': 'D17587987732214', // Default doctor ID
        'is_active': true,
      };

      final response = await _apiService.createPatient(patientData);
      
      if (response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to create patient';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Patient'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      validator: (value) => value?.isEmpty == true ? 'Please enter full name' : null,
                    ),
                    _buildTextField(
                      controller: _dateOfBirthController,
                      label: 'Date of Birth (DD/MM/YYYY)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDate,
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Please select date of birth' : null,
                    ),
                    _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genderOptions,
                      onChanged: (value) => setState(() => _selectedGender = value),
                      validator: (value) => value == null ? 'Please select gender' : null,
                    ),
                    _buildTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Please enter contact number';
                        if (value!.length < 10) return 'Contact number must be at least 10 digits';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Please enter email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Address Information Section
                    _buildSectionHeader('Address Information'),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      maxLines: 2,
                    ),
                    _buildTextField(
                      controller: _cityController,
                      label: 'City',
                    ),
                    _buildTextField(
                      controller: _stateController,
                      label: 'State',
                    ),
                    _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    // Emergency Contact Section
                    _buildSectionHeader('Emergency Contact'),
                    _buildTextField(
                      controller: _emergencyContactNameController,
                      label: 'Emergency Contact Name',
                    ),
                    _buildTextField(
                      controller: _emergencyContactNumberController,
                      label: 'Emergency Contact Number',
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),

                    // Medical Information Section
                    _buildSectionHeader('Medical Information'),
                    _buildDropdown(
                      label: 'Blood Type',
                      value: _selectedBloodType,
                      items: _bloodTypeOptions,
                      onChanged: (value) => setState(() => _selectedBloodType = value),
                    ),
                    _buildTextField(
                      controller: _allergiesController,
                      label: 'Allergies',
                      maxLines: 2,
                    ),
                    _buildTextField(
                      controller: _medicalNotesController,
                      label: 'Medical Notes',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
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
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create Patient',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
