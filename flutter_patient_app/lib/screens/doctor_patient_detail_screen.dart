import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _patientAppointments = [];
  List<Map<String, dynamic>> _medicationHistory = [];
  List<Map<String, dynamic>> _symptomReports = [];
  List<Map<String, dynamic>> _foodEntries = [];
  List<Map<String, dynamic>> _tabletTracking = [];
  Map<String, dynamic>? _prescriptionDetails;
  List<Map<String, dynamic>> _kickCountLogs = [];
  List<Map<String, dynamic>> _mentalHealthLogs = [];
  List<Map<String, dynamic>> _prescriptionDocuments = [];
  List<Map<String, dynamic>> _vitalSignsLogs = [];
  String? _aiSummary;
  bool _isLoadingAISummary = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
  }

  Future<void> _loadPatientDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get doctor ID from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorId = authProvider.patientId ?? '';

      // Load all comprehensive patient data in parallel
      final results = await Future.wait(<Future<Map<String, dynamic>>>[
        _apiService.getPatientDetails(widget.patientId),
        _apiService.getAppointments(patientId: widget.patientId, doctorId: doctorId),
        _apiService.getMedicationHistory(widget.patientId),
        _apiService.getSymptomAnalysisReports(widget.patientId),
        _apiService.getGPT4AnalysisHistory(widget.patientId),
        _apiService.getTabletTrackingHistory(widget.patientId),
        _apiService.getPrescriptionDetails(widget.patientId),
        _apiService.getKickCountHistory(widget.patientId),
        _apiService.getMentalHealthHistory(widget.patientId),
        _apiService.getPrescriptionDocuments(widget.patientId),
        _apiService.getVitalSignsHistory(widget.patientId),
      ]);

      final patientResponse = results[0];
      final appointmentsResponse = results[1];
      final medicationResponse = results[2];
      final symptomsResponse = results[3];
      final foodResponse = results[4];
      final tabletResponse = results[5];
      final prescriptionResponse = results[6];
      final kickCountResponse = results[7];
      final mentalHealthResponse = results[8];
      final prescriptionDocumentsResponse = results[9];
      final vitalSignsResponse = results[10];
      
      if (patientResponse.containsKey('error')) {
        setState(() {
          _error = patientResponse['error'];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _patientData = patientResponse['patient'];
        _patientAppointments = List<Map<String, dynamic>>.from(
          appointmentsResponse['appointments'] ?? []
        );
        // Fix medication history parsing - backend returns 'medication_logs'
        _medicationHistory = List<Map<String, dynamic>>.from(
          medicationResponse['medication_logs'] ?? []
        );
        // Fix symptom reports parsing - backend returns 'analysis_reports'
        _symptomReports = List<Map<String, dynamic>>.from(
          symptomsResponse['analysis_reports'] ?? []
        );
        // Fix food entries parsing - backend returns 'food_data'
        _foodEntries = List<Map<String, dynamic>>.from(
          foodResponse['food_data'] ?? []
        );
        // Fix tablet tracking parsing - backend returns 'tablet_logs'
        _tabletTracking = List<Map<String, dynamic>>.from(
          tabletResponse['tablet_logs'] ?? []
        );
        _prescriptionDetails = prescriptionResponse.containsKey('error') ? null : prescriptionResponse;
        
        // Parse kick count logs - backend returns 'kick_logs'
        _kickCountLogs = List<Map<String, dynamic>>.from(
          kickCountResponse['kick_logs'] ?? []
        );
        
        // Parse mental health logs - backend returns 'data.mood_history'
        _mentalHealthLogs = List<Map<String, dynamic>>.from(
          mentalHealthResponse['data']?['mood_history'] ?? []
        );
        
        // Debug logging
        print('🔍 Flutter Debug - Data loaded:');
        print('  Medication History: ${_medicationHistory.length} items');
        print('  Symptom Reports: ${_symptomReports.length} items');
        print('  Food Entries: ${_foodEntries.length} items');
        print('  Mental Health Logs: ${_mentalHealthLogs.length} items');
        print('  Kick Count Logs: ${_kickCountLogs.length} items');
        print('  Prescription Documents: ${_prescriptionDocuments.length} items');
        print('  Vital Signs Logs: ${_vitalSignsLogs.length} items');
        
        // Parse prescription documents - backend returns 'prescription_documents'
        _prescriptionDocuments = List<Map<String, dynamic>>.from(
          prescriptionDocumentsResponse['prescription_documents'] ?? []
        );
        
        // Parse vital signs logs - backend returns 'vital_signs_logs'
        _vitalSignsLogs = List<Map<String, dynamic>>.from(
          vitalSignsResponse['vital_signs_logs'] ?? []
        );
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load patient details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAISummary() async {
    setState(() {
      _isLoadingAISummary = true;
    });

    try {
      final response = await _apiService.getPatientAISummary(widget.patientId);
      
      if (response.containsKey('error')) {
        print('❌ AI Summary Error: ${response['error']}');
        setState(() {
          _aiSummary = 'Failed to load AI summary: ${response['error']}';
          _isLoadingAISummary = false;
        });
      } else {
        setState(() {
          _aiSummary = response['ai_summary'] ?? 'No AI summary available';
          _isLoadingAISummary = false;
        });
        print('✅ AI Summary loaded successfully');
      }
    } catch (e) {
      setState(() {
        _aiSummary = 'Error loading AI summary: $e';
        _isLoadingAISummary = false;
      });
      print('❌ AI Summary Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientDetails,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              onPressed: _loadPatientDetails,
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

    if (_patientData == null) {
      return const Center(
        child: Text(
          'No patient data available',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientHeader(),
          const SizedBox(height: 24),
          _buildAISummary(),
          const SizedBox(height: 24),
          _buildPersonalInfo(),
          const SizedBox(height: 24),
          _buildMedicalInfo(),
          const SizedBox(height: 24),
          _buildPatientAppointments(),
          const SizedBox(height: 24),
          _buildMedicationHistory(),
          const SizedBox(height: 24),
          _buildFoodNutritionLogs(),
          const SizedBox(height: 24),
          _buildSymptomReports(),
          const SizedBox(height: 24),
          _buildTabletTracking(),
          const SizedBox(height: 24),
          _buildPrescriptionDetails(),
          const SizedBox(height: 24),
          _buildKickCountLogs(),
          const SizedBox(height: 24),
          _buildMentalHealthLogs(),
          const SizedBox(height: 24),
          _buildVitalSignsLogs(),
          const SizedBox(height: 24),
          _buildPrescriptionDocuments(),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    final fullName = (_patientData!['full_name'] ?? 'Unknown Patient').toString();
    final patientId = (_patientData!['patient_id'] ?? '').toString();
    final email = (_patientData!['email'] ?? '').toString();
    final isPregnant = _patientData!['is_pregnant'] ?? false;
    final status = (_patientData!['status'] ?? 'active').toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $patientId',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (isPregnant)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: const Text(
                      '🤱 Pregnant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'active' 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Medical Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_aiSummary == null)
                  IconButton(
                    onPressed: _loadAISummary,
                    icon: _isLoadingAISummary
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_aiSummary == null && !_isLoadingAISummary)
              const Text(
                'Tap refresh to get AI-powered medical summary',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              )
            else if (_isLoadingAISummary)
              const Text(
                'Generating AI summary...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              )
            else if (_aiSummary != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _aiSummary!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Full Name', (_patientData!['full_name'] ?? 'Not provided').toString()),
            _buildInfoRow('Date of Birth', (_patientData!['date_of_birth'] ?? 'Not provided').toString()),
            _buildInfoRow('Blood Type', (_patientData!['blood_type'] ?? 'Not provided').toString()),
            _buildInfoRow('Mobile', (_patientData!['mobile'] ?? 'Not provided').toString()),
            _buildInfoRow('Address', (_patientData!['address'] ?? 'Not provided').toString()),
            _buildInfoRow('Emergency Contact', (_patientData!['emergency_contact'] ?? 'Not provided').toString()),
            if (_patientData!['pregnancy_due_date'] != null && _patientData!['pregnancy_due_date'].toString().isNotEmpty)
              _buildInfoRow('Due Date', _patientData!['pregnancy_due_date'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfo() {
    final medicalHistory = List<String>.from((_patientData!['medical_history'] ?? []).map((e) => e.toString()));
    final allergies = List<String>.from((_patientData!['allergies'] ?? []).map((e) => e.toString()));
    final medications = List<String>.from((_patientData!['current_medications'] ?? []).map((e) => e.toString()));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Medical History
            _buildListSection('Medical History', medicalHistory),
            const SizedBox(height: 12),
            
            // Allergies
            _buildListSection('Allergies', allergies),
            const SizedBox(height: 12),
            
            // Current Medications
            _buildListSection('Current Medications', medications),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientAppointments() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Patient Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_patientAppointments.length} appointments',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showCreateAppointmentDialog(),
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  tooltip: 'Add Appointment',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_patientAppointments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'No appointments scheduled',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateAppointmentDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Appointment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._patientAppointments.map((appointment) => _buildAppointmentCard(appointment)),
          ],
        ),
      ),
    );
  }

  Widget _buildMentalHealthLogs() {
    final mentalHealthLogs = _mentalHealthLogs;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Mental Health Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${mentalHealthLogs.length} entries',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (mentalHealthLogs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No mental health logs available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...mentalHealthLogs.take(5).map((log) => _buildMentalHealthLogCard(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text(
            'None reported',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.primary)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final appointmentDate = appointment['appointment_date'] ?? '';
    final appointmentTime = appointment['appointment_time'] ?? '';
    final appointmentType = appointment['appointment_type'] ?? 'General';
    final appointmentStatus = appointment['appointment_status'] ?? 'scheduled';
    final notes = appointment['notes'] ?? '';

    Color statusColor = _getStatusColor(appointmentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$appointmentDate at $appointmentTime',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  appointmentStatus.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.medical_services, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                appointmentType,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ],
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
    final formKey = GlobalKey<FormState>();
    String appointmentDate = '';
    String appointmentTime = '';
    String appointmentType = 'General';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Appointment for ${widget.patientName}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    hintText: '2024-01-15',
                  ),
                  onChanged: (value) => appointmentDate = value,
                  validator: (value) => value?.isEmpty ?? true ? 'Date is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Time (HH:MM)',
                    hintText: '14:30',
                  ),
                  onChanged: (value) => appointmentTime = value,
                  validator: (value) => value?.isEmpty ?? true ? 'Time is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: appointmentType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'Consultation', child: Text('Consultation')),
                    DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                    DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                  ],
                  onChanged: (value) => appointmentType = value ?? 'General',
                ),
                const SizedBox(height: 16),
                TextFormField(
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
                await _createAppointment(appointmentDate, appointmentTime, appointmentType, notes);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAppointment(String date, String time, String type, String notes) async {
    try {
      final response = await _apiService.createAppointment(
        patientId: widget.patientId,
        appointmentDate: date,
        appointmentTime: time,
        appointmentType: type,
        notes: notes,
      );

      if (response.containsKey('error')) {
        _showErrorSnackBar(response['error']);
      } else {
        _showSuccessSnackBar('Appointment created successfully');
        _loadPatientDetails(); // Refresh the data
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create appointment: $e');
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

  Widget _buildMentalHealthLogCard(Map<String, dynamic> log) {
    final date = log['date'] ?? 'Unknown date';
    final mood = log['mood'] ?? 'Not specified';
    final stress = log['stress_level'] ?? 'Not specified';
    final notes = log['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Mood: $mood',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Stress Level: $stress',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              const Icon(Icons.medication, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Medication History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_medicationHistory.length} entries',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_medicationHistory.isEmpty)
            const Text(
              'No medication history available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: _medicationHistory.take(5).map((medication) {
                final medicationName = (medication['medication_name'] ?? 'Unknown Medication').toString();
                final dosage = (medication['dosage'] ?? 'N/A').toString();
                final frequency = (medication['frequency'] ?? 'N/A').toString();
                final startDate = (medication['start_date'] ?? '').toString();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                medicationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              startDate,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dosage: $dosage • Frequency: $frequency',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (_medicationHistory.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Showing 5 of ${_medicationHistory.length} medications',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildFoodNutritionLogs() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              const Icon(Icons.restaurant, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Food & Nutrition Logs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_foodEntries.length} entries',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_foodEntries.isEmpty)
            const Text(
              'No food entries available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: _foodEntries.take(5).map((food) {
                final foodInput = (food['food_input'] ?? food['food_details'] ?? 'Unknown Food').toString();
                final timestamp = (food['timestamp'] ?? food['created_at'] ?? '').toString();
                final mealType = (food['meal_type'] ?? '').toString();
                final pregnancyWeek = food['pregnancy_week'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                foodInput,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (mealType.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  mealType,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Week $pregnancyWeek',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timestamp.isNotEmpty ? timestamp.split('T')[0] : '',
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
                );
              }).toList(),
            ),
          if (_foodEntries.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Showing 5 of ${_foodEntries.length} food entries',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildSymptomReports() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              const Icon(Icons.health_and_safety, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Symptom Analysis Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_symptomReports.length} reports',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_symptomReports.isEmpty)
            const Text(
              'No symptom reports available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: _symptomReports.take(3).map((report) {
                final symptoms = (report['symptoms'] ?? 'Unknown symptoms').toString();
                final analysis = (report['analysis'] ?? report['ai_analysis'] ?? '').toString();
                final timestamp = (report['timestamp'] ?? report['created_at'] ?? '').toString();
                final severity = (report['severity'] ?? 'Normal').toString();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                symptoms,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(severity).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                severity,
                                style: TextStyle(
                                  color: _getSeverityColor(severity),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (analysis.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            analysis.length > 100 ? '${analysis.substring(0, 100)}...' : analysis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          timestamp.isNotEmpty ? timestamp.split('T')[0] : '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (_symptomReports.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Showing 3 of ${_symptomReports.length} symptom reports',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildTabletTracking() {
    return GestureDetector(
      onTap: () => _navigateToTabletTracking(),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication_liquid, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Tablet Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_tabletTracking.length} records',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tabletTracking.isEmpty)
            const Text(
              'No tablet tracking data available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: _tabletTracking.take(5).map((tracking) {
                final medicationName = (tracking['medication_name'] ?? 'Unknown Medication').toString();
                final takenAt = (tracking['taken_at'] ?? tracking['timestamp'] ?? '').toString();
                final dosage = (tracking['dosage'] ?? 'N/A').toString();
                final status = (tracking['status'] ?? 'taken').toString();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status == 'taken' ? AppColors.success : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medicationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Dosage: $dosage',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          takenAt.isNotEmpty ? takenAt.split('T')[0] : '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (_tabletTracking.length > 5) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Showing 5 of ${_tabletTracking.length} tracking records',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildPrescriptionDetails() {
    return GestureDetector(
      onTap: () => _navigateToPrescriptionDetails(),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Prescription Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_prescriptionDetails != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_prescriptionDetails == null)
            const Text(
              'No prescription details available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            if (_prescriptionDetails!['prescriptions'] != null)
              Column(
                children: (_prescriptionDetails!['prescriptions'] as List).map((prescription) {
                  final medicationName = (prescription['medication_name'] ?? 'Unknown').toString();
                  final dosage = (prescription['dosage'] ?? 'N/A').toString();
                  final instructions = (prescription['instructions'] ?? '').toString();
                  final status = (prescription['status'] ?? 'active').toString();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  medicationName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: status == 'active' ? AppColors.success.withOpacity(0.1) : AppColors.textSecondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'active' ? AppColors.success : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dosage: $dosage',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (instructions.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              instructions,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              const Text(
                'Prescription data format not supported',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        return AppColors.error;
      case 'medium':
      case 'moderate':
        return AppColors.warning;
      case 'low':
      case 'mild':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildKickCountLogs() {
    return GestureDetector(
      onTap: () => _navigateToKickCountLogs(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.child_care,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kick Count Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kickCountLogs.isNotEmpty ? Colors.purple : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_kickCountLogs.length} entries',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_kickCountLogs.isNotEmpty) ...[
              Column(
                children: _kickCountLogs.take(3).map((kickLog) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.baby_changing_station,
                            color: Colors.purple,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(kickLog['kick_count'] ?? 0).toString()} kicks in ${(kickLog['session_duration_minutes'] ?? 0).toString()} min',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(kickLog['date'] ?? 'Unknown date').toString()} at ${(kickLog['time'] ?? 'Unknown time').toString()}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (_kickCountLogs.length > 3)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Tap to view all ${_kickCountLogs.length} kick count logs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.child_care_outlined,
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No kick count logs found for this patient.\nPatient can track fetal movements using the kick counter feature.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Navigation methods for detailed views
  void _navigateToMedicationHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Medication History - ${widget.patientName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
                          child: _medicationHistory.isEmpty
                    ? const Center(child: Text('No medication history found for this patient.\nThis is normal for new patients.'))
              : ListView.builder(
                  itemCount: _medicationHistory.length,
                  itemBuilder: (context, index) {
                    final medication = _medicationHistory[index];
                    return Card(
                      child: ListTile(
                        title: Text(medication['medication_name']?.toString() ?? 'Unknown'),
                        subtitle: Text('Dosage: ${medication['dosage']?.toString() ?? 'N/A'}\nFrequency: ${medication['frequency']?.toString() ?? 'N/A'}'),
                        trailing: Text(medication['start_date']?.toString() ?? ''),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToFoodNutrition() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Food & Nutrition - ${widget.patientName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
                          child: _foodEntries.isEmpty
                    ? const Center(child: Text('No food/nutrition logs found for this patient.\nPatient can add food entries using the nutrition feature in the patient app.'))
              : ListView.builder(
                  itemCount: _foodEntries.length,
                  itemBuilder: (context, index) {
                    final food = _foodEntries[index];
                    return Card(
                      child: ListTile(
                        title: Text(food['food_input']?.toString() ?? food['food_details']?.toString() ?? 'Unknown Food'),
                        subtitle: Text('Week: ${food['pregnancy_week'] ?? 0}\nMeal: ${food['meal_type']?.toString() ?? 'N/A'}'),
                        trailing: Text(food['timestamp']?.toString().split('T')[0] ?? ''),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToSymptomReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Symptom Reports - ${widget.patientName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
                          child: _symptomReports.isEmpty
                    ? const Center(child: Text('No symptom reports found for this patient.\nPatient can add symptom reports using the health tracking feature.'))
              : ListView.builder(
                  itemCount: _symptomReports.length,
                  itemBuilder: (context, index) {
                    final report = _symptomReports[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(report['symptoms']?.toString() ?? 'Unknown symptoms'),
                        subtitle: Text('Severity: ${report['severity']?.toString() ?? 'Normal'}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(report['analysis']?.toString() ?? report['ai_analysis']?.toString() ?? 'No analysis available'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToTabletTracking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tablet Tracking - ${widget.patientName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
                          child: _tabletTracking.isEmpty
                    ? const Center(child: Text('No tablet tracking data found for this patient.\nTracking will appear here once patient starts taking medications.'))
              : ListView.builder(
                  itemCount: _tabletTracking.length,
                  itemBuilder: (context, index) {
                    final tracking = _tabletTracking[index];
                    final status = tracking['status']?.toString() ?? 'taken';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          status == 'taken' ? Icons.check_circle : Icons.warning,
                          color: status == 'taken' ? AppColors.success : AppColors.warning,
                        ),
                        title: Text(tracking['medication_name']?.toString() ?? 'Unknown'),
                        subtitle: Text('Dosage: ${tracking['dosage']?.toString() ?? 'N/A'}'),
                        trailing: Text(tracking['taken_at']?.toString().split('T')[0] ?? ''),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToPrescriptionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Prescription Details - ${widget.patientName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
                          child: _prescriptionDetails == null
                    ? const Center(child: Text('No prescription details found for this patient.\nPrescriptions will appear here once prescribed by doctors.'))
              : _prescriptionDetails!['prescriptions'] != null
                  ? ListView.builder(
                      itemCount: (_prescriptionDetails!['prescriptions'] as List).length,
                      itemBuilder: (context, index) {
                        final prescription = (_prescriptionDetails!['prescriptions'] as List)[index];
                        return Card(
                          child: ExpansionTile(
                            title: Text(prescription['medication_name']?.toString() ?? 'Unknown'),
                            subtitle: Text('Status: ${prescription['status']?.toString() ?? 'active'}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dosage: ${prescription['dosage']?.toString() ?? 'N/A'}'),
                                    const SizedBox(height: 8),
                                    Text('Instructions: ${prescription['instructions']?.toString() ?? 'No instructions'}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('Prescription data format not supported')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToKickCountLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kick Count Logs - ${widget.patientName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _kickCountLogs.isEmpty
              ? const Center(child: Text('No kick count logs found for this patient.\nPatient can track fetal movements using the kick counter feature in the patient app.'))
              : ListView.builder(
                  itemCount: _kickCountLogs.length,
                  itemBuilder: (context, index) {
                    final kickLog = _kickCountLogs[index];
                    final kickCount = kickLog['kick_count']?.toString() ?? '0';
                    final duration = kickLog['session_duration_minutes']?.toString() ?? '0';
                    final date = kickLog['date']?.toString() ?? 'Unknown';
                    final time = kickLog['time']?.toString() ?? 'Unknown';
                    final notes = kickLog['notes']?.toString() ?? '';
                    final quality = kickLog['quality_rating']?.toString() ?? 'normal';
                    final pregnancyWeek = kickLog['pregnancy_week']?.toString() ?? '0';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.child_care,
                            color: Colors.purple,
                            size: 20,
                          ),
                        ),
                        title: Text('$kickCount kicks in $duration minutes'),
                        subtitle: Text('$date at $time • Week $pregnancyWeek'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Quality: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getQualityColor(quality).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getQualityColor(quality)),
                                      ),
                                      child: Text(
                                        quality.toUpperCase(),
                                        style: TextStyle(
                                          color: _getQualityColor(quality),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('Notes: $notes'),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Logged: ${kickLog['created_at']?.toString().split('T')[0] ?? date}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'strong':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'weak':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildVitalSignsLogs() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Vital Signs Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_vitalSignsLogs.length} entries',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_vitalSignsLogs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No vital signs logs available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ..._vitalSignsLogs.take(5).map((log) => _buildVitalSignsLogCard(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsLogCard(Map<String, dynamic> log) {
    final timestamp = (log['timestamp'] ?? log['created_at'] ?? '').toString();
    final bloodPressure = (log['blood_pressure'] ?? 'N/A').toString();
    final heartRate = (log['heart_rate'] ?? 'N/A').toString();
    final temperature = (log['temperature'] ?? 'N/A').toString();
    final weight = (log['weight'] ?? 'N/A').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    timestamp,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildVitalSignItem('BP', bloodPressure),
                ),
                Expanded(
                  child: _buildVitalSignItem('HR', heartRate),
                ),
                Expanded(
                  child: _buildVitalSignItem('Temp', temperature),
                ),
                Expanded(
                  child: _buildVitalSignItem('Weight', weight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionDocuments() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Prescription Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_prescriptionDocuments.length} documents',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_prescriptionDocuments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No prescription documents available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ..._prescriptionDocuments.take(5).map((doc) => _buildPrescriptionDocumentCard(doc)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionDocumentCard(Map<String, dynamic> doc) {
    final prescriptionId = (doc['prescription_id'] ?? 'Unknown ID').toString();
    final medicationName = (doc['medication_name'] ?? 'Unknown Medication').toString();
    final dosage = (doc['dosage'] ?? 'N/A').toString();
    final frequency = (doc['frequency'] ?? 'N/A').toString();
    final timestamp = (doc['timestamp'] ?? doc['created_at'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    medicationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $prescriptionId • Dosage: $dosage • Frequency: $frequency',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
