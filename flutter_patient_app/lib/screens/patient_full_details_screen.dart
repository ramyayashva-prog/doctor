import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class PatientFullDetailsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientFullDetailsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientFullDetailsScreen> createState() => _PatientFullDetailsScreenState();
}

class _PatientFullDetailsScreenState extends State<PatientFullDetailsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _fullDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getPatientFullDetails(widget.patientId);
      
      if (result.containsKey('error')) {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _fullDetails = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load patient details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName} - Full Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFullDetails,
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
              onPressed: _loadFullDetails,
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

    if (_fullDetails == null) {
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
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildHealthDataSections(),
        ],
      ),
    );
  }

  Widget _buildPatientHeader() {
    final patientInfo = _fullDetails!['patient_info'];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
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
                    (patientInfo['full_name'] ?? 'P')[0].toUpperCase(),
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
                        patientInfo['full_name'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_fullDetails!['patient_id']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        patientInfo['email'] ?? '',
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
                if (patientInfo['is_pregnant'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pregnant_woman, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Pregnant',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (patientInfo['status'] ?? 'active').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _fullDetails!['summary'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Data Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildSummaryCard('Medications', summary['total_medications'], Icons.medication, AppColors.primary),
            _buildSummaryCard('Symptoms', summary['total_symptoms'], Icons.health_and_safety, AppColors.warning),
            _buildSummaryCard('Food Entries', summary['total_food_entries'], Icons.restaurant, AppColors.success),
            _buildSummaryCard('Mental Health', summary['total_mental_health'], Icons.psychology, AppColors.info),
            _buildSummaryCard('Appointments', summary['total_appointments'], Icons.calendar_today, AppColors.secondary),
            _buildSummaryCard('Prescriptions', summary['total_prescriptions'], Icons.description, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildHealthDataSections() {
    final healthData = _fullDetails!['health_data'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Health Data',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        // Food Data
        if (healthData['food_data'].isNotEmpty)
          _buildHealthDataSection(
            'Food & Nutrition Logs',
            healthData['food_data'],
            Icons.restaurant,
            AppColors.success,
            (item) => '${item['food_input'] ?? item['food_details'] ?? 'Unknown'}',
          ),
        
        // Symptom Reports
        if (healthData['symptom_analysis_reports'].isNotEmpty)
          _buildHealthDataSection(
            'Symptom Analysis Reports',
            healthData['symptom_analysis_reports'],
            Icons.health_and_safety,
            AppColors.warning,
            (item) => '${item['symptom_text'] ?? 'Unknown symptoms'}',
          ),
        
        // Mental Health
        if (healthData['mental_health_logs'].isNotEmpty)
          _buildHealthDataSection(
            'Mental Health Logs',
            healthData['mental_health_logs'],
            Icons.psychology,
            AppColors.info,
            (item) => 'Mood: ${item['mood'] ?? 'Unknown'}',
          ),
        
        // Appointments
        if (healthData['appointments'].isNotEmpty)
          _buildHealthDataSection(
            'Appointments',
            healthData['appointments'],
            Icons.calendar_today,
            AppColors.secondary,
            (item) => '${item['appointment_type'] ?? 'General'} - ${item['appointment_date'] ?? ''}',
          ),
      ],
    );
  }

  Widget _buildHealthDataSection(String title, List<dynamic> items, IconData icon, Color color, String Function(dynamic) itemTitle) {
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
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length} entries',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.take(3).map((item) => _buildHealthDataItem(item, itemTitle)),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Showing 3 of ${items.length} entries',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDataItem(dynamic item, String Function(dynamic) itemTitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemTitle(item),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (item['timestamp'] != null || item['created_at'] != null)
            Text(
              item['timestamp'] ?? item['created_at'] ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
