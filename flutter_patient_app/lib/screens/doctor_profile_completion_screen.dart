import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_button.dart';
import '../services/api_service.dart';

class DoctorProfileCompletionScreen extends StatefulWidget {
  const DoctorProfileCompletionScreen({super.key});

  @override
  State<DoctorProfileCompletionScreen> createState() => _DoctorProfileCompletionScreenState();
}

class _DoctorProfileCompletionScreenState extends State<DoctorProfileCompletionScreen> {
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
  
  String _selectedSpecialization = '';
  List<String> _selectedLanguages = [];
  bool _isLoading = false;

  final List<String> _specializations = [
    'General Medicine',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'Psychiatry',
    'Ophthalmology',
    'ENT',
    'Urology',
    'Gastroenterology',
    'Pulmonology',
    'Endocrinology',
    'Oncology',
    'Radiology',
    'Anesthesiology',
    'Emergency Medicine',
    'Family Medicine',
    'Internal Medicine'
  ];

  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Gujarati',
    'Marathi',
    'Punjabi'
  ];

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
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecialization.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a specialization'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Get doctor_id from auth provider
    final doctorId = authProvider.patientId; // doctor_id is stored in patientId field
    
    print('🔍 Doctor Profile Completion Debug:');
    print('  Doctor ID from auth provider: $doctorId');
    print('  Auth provider logged in: ${authProvider.isLoggedIn}');
    print('  Auth provider role: ${authProvider.role}');
    print('  Auth provider email: ${authProvider.email}');
    print('  Auth provider username: ${authProvider.username}');
    print('  Auth provider token: ${authProvider.token?.substring(0, 20)}...');
    
    if (doctorId == null || doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor ID not found. Please complete OTP verification first.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Call the API to complete doctor profile
      final apiService = ApiService();
      
      print('🔍 Calling completeDoctorProfile API with:');
      print('  Doctor ID: $doctorId');
      print('  First Name: ${_firstNameController.text.trim()}');
      print('  Last Name: ${_lastNameController.text.trim()}');
      print('  Specialization: $_selectedSpecialization');
      print('  License Number: ${_licenseNumberController.text.trim()}');
      print('  Languages: $_selectedLanguages');
      
      final result = await apiService.completeDoctorProfile(
        doctorId: doctorId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        specialization: _selectedSpecialization,
        licenseNumber: _licenseNumberController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
        hospitalName: _hospitalController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        consultationFee: int.tryParse(_consultationFeeController.text.trim()) ?? 0,
        languages: _selectedLanguages,
        qualifications: [], // Add qualifications if needed
      );
      
      print('🔍 API Response: $result');
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile completed successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Navigate to doctor login page
          Navigator.pushReplacementNamed(context, '/login', arguments: 'doctor');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to complete profile'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
        title: const Text('Complete Doctor Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Header
                Icon(
                  Icons.person_add,
                  size: 70,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Complete Your Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide your professional information',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Personal Information
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Specialization Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSpecialization.isEmpty ? null : _selectedSpecialization,
                  decoration: const InputDecoration(
                    labelText: 'Specialization *',
                    prefixIcon: Icon(Icons.medical_services),
                    border: OutlineInputBorder(),
                  ),
                  items: _specializations.map((String specialization) {
                    return DropdownMenuItem<String>(
                      value: specialization,
                      child: Text(specialization),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSpecialization = newValue ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Specialization is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // License Number
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'License Number *',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'License number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Experience Years
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.work),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Hospital Name
                TextFormField(
                  controller: _hospitalController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital/Clinic Name',
                    prefixIcon: Icon(Icons.local_hospital),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Address Information
                Text(
                  'Address Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // State
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.map),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Pincode
                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    prefixIcon: Icon(Icons.pin_drop),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Consultation Fee
                TextFormField(
                  controller: _consultationFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Fee (₹)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Languages
                Text(
                  'Languages Spoken',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _languages.map((language) {
                    final isSelected = _selectedLanguages.contains(language);
                    return FilterChip(
                      label: Text(language),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedLanguages.add(language);
                          } else {
                            _selectedLanguages.remove(language);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Complete Profile Button
                LoadingButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  isLoading: _isLoading,
                  text: 'Complete Profile',
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
