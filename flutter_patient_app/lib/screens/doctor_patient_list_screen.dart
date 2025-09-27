import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'doctor_patient_detail_screen.dart';
import 'add_patient_screen.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({super.key});

  @override
  State<DoctorPatientListScreen> createState() => _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get doctor_id from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorId = authProvider.patientId; // doctor_id is stored in patientId field
      
      if (doctorId == null || doctorId.isEmpty) {
        setState(() {
          _error = 'Doctor ID not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getDoctorPatients(doctorId);
      
      if (response.containsKey('error')) {
        setState(() {
          _error = response['error'];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _patients = List<Map<String, dynamic>>.from(response['patients'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load patients: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewPatient() async {
    try {
      // Navigate to Add Patient screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddPatientScreen(),
        ),
      );
      
      // If patient was created successfully, refresh the patient list
      if (result == true) {
        _loadPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New patient added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navigating to Add Patient screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening Add Patient screen: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    
    return _patients.where((patient) {
      final name = (patient['name'] ?? '').toLowerCase();
      final email = (patient['email'] ?? '').toLowerCase();
      final patientId = (patient['patient_id'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || 
             email.contains(query) || 
             patientId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient List'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Patient Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.background,
            child: Row(
              children: [
                Text(
                  '${_filteredPatients.length} patients found',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Patient List
          Expanded(
            child: _buildPatientList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPatient,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('New Patient'),
      ),
    );
  }

  Widget _buildPatientList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatients,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No patients found' : 'No patients match your search',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          return _buildPatientCard(patient);
        },
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final name = patient['name'] ?? 'Unknown Patient';
    final email = patient['email'] ?? '';
    final patientId = patient['patient_id'] ?? '';
    final isPregnant = patient['is_pregnant'] ?? false;
    final isProfileComplete = patient['is_profile_complete'] ?? false;
    final bloodType = patient['blood_type'] ?? '';
    final mobile = patient['mobile'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewPatientDetails(patient),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 24,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $patientId',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (isPregnant)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.info),
                          ),
                          child: const Text(
                            'Pregnant',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (!isProfileComplete)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning),
                          ),
                          child: const Text(
                            'Incomplete',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (email.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.email, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (mobile.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                mobile,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (bloodType.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.favorite, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Blood Type: $bloodType',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorPatientDetailScreen(
          patientId: patient['patient_id'] ?? patient['object_id'] ?? '',
          patientName: patient['name'] ?? 'Unknown Patient',
        ),
      ),
    );
  }
}

                              const Icon(Icons.favorite, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Blood Type: $bloodType',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorPatientDetailScreen(
          patientId: patient['patient_id'] ?? patient['object_id'] ?? '',
          patientName: patient['name'] ?? 'Unknown Patient',
        ),
      ),
    );
  }
}

                              const Icon(Icons.favorite, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Blood Type: $bloodType',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorPatientDetailScreen(
          patientId: patient['patient_id'] ?? patient['object_id'] ?? '',
          patientName: patient['name'] ?? 'Unknown Patient',
        ),
      ),
    );
  }
}
