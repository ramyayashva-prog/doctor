import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final bool showTodayOnly;
  
  const DoctorAppointmentsScreen({super.key, this.showTodayOnly = false});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> appointments) {
    List<Map<String, dynamic>> filteredAppointments = appointments;
    
    // Filter for today's appointments if requested
    if (widget.showTodayOnly) {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      filteredAppointments = filteredAppointments.where((appointment) {
        return appointment['appointment_date'] == todayString;
      }).toList();
    }
    
    // Filter by status (if not 'all')
    if (_selectedStatus != 'all') {
      filteredAppointments = filteredAppointments.where((appointment) {
        return appointment['appointment_status'] == _selectedStatus;
      }).toList();
    }
    
    return filteredAppointments;
  }

  Future<void> _loadData() async {
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

      // Load appointments and patients in parallel
      final results = await Future.wait([
        _apiService.getAppointments(doctorId: doctorId), // Get all appointments, filter in Flutter
        _apiService.getDoctorPatients(doctorId),
      ]);

      final appointmentsResponse = results[0];
      final patientsResponse = results[1];

      if (appointmentsResponse.containsKey('error')) {
        setState(() {
          _error = appointmentsResponse['error'];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> appointments = List<Map<String, dynamic>>.from(appointmentsResponse['appointments'] ?? []);
      
      // Apply filters
      appointments = _applyFilters(appointments);

      setState(() {
        _appointments = appointments;
        _patients = List<Map<String, dynamic>>.from(patientsResponse['patients'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showTodayOnly ? 'Today\'s Appointments' : 'Appointments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Appointments')),
                          DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                          DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Showing ${_appointments.length} appointment${_appointments.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Appointments List
          Expanded(
            child: _buildAppointmentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAppointmentDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppointmentsList() {
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
              onPressed: _loadData,
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

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No appointments found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showCreateAppointmentDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create First Appointment'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final patientName = appointment['patient_name'] ?? 'Unknown Patient';
    final appointmentDate = appointment['appointment_date'] ?? '';
    final appointmentTime = appointment['appointment_time'] ?? '';
    final appointmentType = appointment['appointment_type'] ?? 'General';
    final appointmentStatus = appointment['appointment_status'] ?? 'scheduled';
    final notes = appointment['notes'] ?? '';

    Color statusColor = _getStatusColor(appointmentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$appointmentDate at $appointmentTime',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    appointmentStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.medical_services, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  appointmentType,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditAppointmentDialog(appointment),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteAppointment(appointment['appointment_id']),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.info;
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showCreateAppointmentDialog() {
    _showAppointmentDialog();
  }

  void _showEditAppointmentDialog(Map<String, dynamic> appointment) {
    _showAppointmentDialog(appointment: appointment);
  }

  void _showAppointmentDialog({Map<String, dynamic>? appointment}) {
    final isEditing = appointment != null;
    final formKey = GlobalKey<FormState>();
    
    String? selectedPatientId = appointment?['patient_id'];
    String appointmentDate = appointment?['appointment_date'] ?? '';
    String appointmentTime = appointment?['appointment_time'] ?? '';
    
    // Valid appointment types (must match dropdown items exactly)
    final validTypes = ['General', 'Consultation', 'Follow-up', 'Emergency'];
    String appointmentType = appointment?['appointment_type'] ?? 'General';
    // Ensure the appointment type is valid, fallback to 'General' if not
    if (!validTypes.contains(appointmentType)) {
      appointmentType = 'General';
    }
    
    // Valid appointment statuses  
    final validStatuses = ['scheduled', 'confirmed', 'completed', 'cancelled'];
    String appointmentStatus = appointment?['appointment_status'] ?? 'scheduled';
    // Ensure the appointment status is valid, fallback to 'scheduled' if not
    if (!validStatuses.contains(appointmentStatus)) {
      appointmentStatus = 'scheduled';
    }
    
    String notes = appointment?['notes'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Appointment' : 'Create Appointment'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Patient Selection
                if (!isEditing) ...[
                  DropdownButtonFormField<String>(
                    value: selectedPatientId,
                    decoration: const InputDecoration(labelText: 'Patient'),
                    items: _patients.map((patient) => DropdownMenuItem<String>(
                      value: patient['patient_id'],
                      child: Text(patient['name'] ?? 'Unknown'),
                    )).toList(),
                    onChanged: (value) => selectedPatientId = value,
                    validator: (value) => value == null ? 'Please select a patient' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Date
                TextFormField(
                  initialValue: appointmentDate,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    hintText: '2024-01-15',
                  ),
                  onChanged: (value) => appointmentDate = value,
                  validator: (value) => value?.isEmpty ?? true ? 'Date is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Time
                TextFormField(
                  initialValue: appointmentTime,
                  decoration: const InputDecoration(
                    labelText: 'Time (HH:MM)',
                    hintText: '14:30',
                  ),
                  onChanged: (value) => appointmentTime = value,
                  validator: (value) => value?.isEmpty ?? true ? 'Time is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Type
                DropdownButtonFormField<String>(
                  value: appointmentType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: validTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) => appointmentType = value ?? 'General',
                ),
                const SizedBox(height: 16),
                
                // Status (only for editing)
                if (isEditing) ...[
                  DropdownButtonFormField<String>(
                    value: appointmentStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: validStatuses.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status[0].toUpperCase() + status.substring(1)),
                    )).toList(),
                    onChanged: (value) => appointmentStatus = value ?? 'scheduled',
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Notes
                TextFormField(
                  initialValue: notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Additional notes...',
                  ),
                  maxLines: 3,
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                
                if (isEditing) {
                  await _updateAppointment(
                    appointment['appointment_id'],
                    appointmentDate,
                    appointmentTime,
                    appointmentType,
                    appointmentStatus,
                    notes,
                  );
                } else {
                  await _createAppointment(
                    selectedPatientId!,
                    appointmentDate,
                    appointmentTime,
                    appointmentType,
                    notes,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAppointment(String patientId, String date, String time, String type, String notes) async {
    try {
      final response = await _apiService.createAppointment(
        patientId: patientId,
        appointmentDate: date,
        appointmentTime: time,
        appointmentType: type,
        notes: notes,
      );

      if (response.containsKey('error')) {
        _showErrorSnackBar(response['error']);
      } else {
        _showSuccessSnackBar('Appointment created successfully');
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create appointment: $e');
    }
  }

  Future<void> _updateAppointment(String appointmentId, String date, String time, String type, String status, String notes) async {
    try {
      final response = await _apiService.updateAppointment(
        appointmentId: appointmentId,
        appointmentDate: date,
        appointmentTime: time,
        appointmentType: type,
        appointmentStatus: status,
        notes: notes,
      );

      if (response.containsKey('error')) {
        _showErrorSnackBar(response['error']);
      } else {
        _showSuccessSnackBar('Appointment updated successfully');
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update appointment: $e');
    }
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _apiService.deleteAppointment(appointmentId);

        if (response.containsKey('error')) {
          _showErrorSnackBar(response['error']);
        } else {
          _showSuccessSnackBar('Appointment deleted successfully');
          _loadData();
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete appointment: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
