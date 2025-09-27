import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'doctor_patient_list_screen.dart';
import 'doctor_appointments_screen.dart';
import 'simple_doctor_profile_screen.dart';
import 'simple_voice_recording_screen.dart';
import 'add_patient_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  int _totalPatients = 0;
  int _todayAppointments = 0;
  int _pendingReports = 0;
  int _emergencyAlerts = 0;
  bool _isLoadingStats = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Get doctor_id from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorId = authProvider.patientId; // doctor_id is stored in patientId field
      
      if (doctorId == null || doctorId.isEmpty) {
        setState(() {
          _error = 'Doctor ID not found. Please login again.';
        });
        return;
      }

      // Load all dashboard statistics
      final patientsResponse = await _apiService.getDoctorPatients(doctorId);
      final statsResponse = await _apiService.getDoctorDashboardStats();
      
      if (!patientsResponse.containsKey('error')) {
        setState(() {
          _totalPatients = patientsResponse['total_count'] ?? 0;
        });
      }
      
      if (!statsResponse.containsKey('error')) {
        setState(() {
          _todayAppointments = statsResponse['today_appointments'] ?? 0;
          _pendingReports = statsResponse['pending_reports'] ?? 0;
          _emergencyAlerts = statsResponse['emergency_alerts'] ?? 0;
        });
      }
      
      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              print('🔍 Menu selected: $value');
              switch (value) {
                case 'profile':
                  print('🔍 Navigating to SimpleDoctorProfileScreen...');
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  print('🔍 Current AuthProvider state:');
                  print('  isLoggedIn: ${authProvider.isLoggedIn}');
                  print('  patientId: ${authProvider.patientId}');
                  print('  email: ${authProvider.email}');
                  print('  role: ${authProvider.role}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleDoctorProfileScreen(),
                    ),
                  );
                  break;
                case 'settings':
                  print('🔍 Settings selected');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings coming soon!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  break;
                case 'logout':
                  print('🔍 Logout selected');
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardHome(),
          _buildPatientsTab(),
          _buildAppointmentsTab(),
          _buildReportsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHome() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      Text(
                        'Welcome back, ${authProvider.username ?? 'Doctor'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${authProvider.patientId ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildClickableStatCard(
                      'Total Patients', 
                      _isLoadingStats ? '...' : '$_totalPatients', 
                      Icons.people, 
                      AppColors.info,
                      () => _navigateToPatientList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildClickableStatCard(
                      'Today\'s Appointments', 
                      _isLoadingStats ? '...' : '$_todayAppointments', 
                      Icons.calendar_today, 
                      AppColors.success,
                      () => _navigateToAppointments(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildClickableStatCard(
                      'Pending Reports', 
                      _isLoadingStats ? '...' : '$_pendingReports', 
                      Icons.assignment, 
                      AppColors.warning,
                      () => _navigateToIncompletePatients(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildClickableStatCard(
                      'Emergency Alerts', 
                      _isLoadingStats ? '...' : '$_emergencyAlerts', 
                      Icons.emergency, 
                      AppColors.error,
                      () => _navigateToEmergencyAlerts(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Doctor Actions
              const Text(
                'Doctor Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Add Appointments Button
              _buildActionButton(
                'Add Appointment',
                'Schedule a new appointment with patient',
                Icons.calendar_today,
                AppColors.info,
                () => _addAppointment(),
              ),
              const SizedBox(height: 12),
              
              // New Patient Button
              _buildActionButton(
                'New Patient',
                'Add a new patient to the system',
                Icons.person_add,
                AppColors.primary,
                () => _addNewPatient(),
              ),
              const SizedBox(height: 12),
              
              // Video Call Button
              _buildActionButton(
                'Video Call',
                'Start a WhatsApp video call',
                Icons.video_call,
                Colors.green,
                () => _startVideoCall(),
              ),
              const SizedBox(height: 12),
              
              // Voice Dictation Button
              _buildActionButton(
                'Voice Dictation',
                'Start voice recording and transcription',
                Icons.mic,
                Colors.orange,
                () => _startVoiceDictation(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
        ),
      ),
    );
  }

  Widget _buildPatientsTab() {
    return const DoctorPatientListScreen();
  }

  Widget _buildAppointmentsTab() {
    return const DoctorAppointmentsScreen();
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Reports & Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPatientList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorPatientListScreen(),
      ),
    );
  }

  void _navigateToAppointments() {
    // Navigate to today's appointments only
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorAppointmentsScreen(showTodayOnly: true),
      ),
    );
  }

  void _navigateToIncompletePatients() {
    // Navigate to patient list and show a filter dialog or filtered view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorPatientListScreen(),
      ),
    );
    // TODO: Add filter functionality to show only incomplete profiles
    _showInfoDialog('Pending Reports', 'Shows patients with incomplete profiles that need attention.');
  }

  void _navigateToEmergencyAlerts() {
    // Navigate to patient list with emergency filter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorPatientListScreen(),
      ),
    );
    // TODO: Add filter functionality to show only emergency cases
    _showInfoDialog('Emergency Alerts', 'Shows patients with high stress levels or urgent medical attention needed.');
  }

  void _addAppointment() {
    // Switch to appointments tab
    setState(() {
      _selectedIndex = 2; // Appointments tab
    });
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
      
      // If patient was created successfully, refresh the dashboard
      if (result == true) {
        _loadDashboardStats();
        _showSuccessSnackBar('New patient added successfully!');
      }
    } catch (e) {
      print('❌ Error navigating to Add Patient screen: $e');
      _showErrorSnackBar('Error opening Add Patient screen: $e');
    }
  }

  Future<void> _startVideoCall() async {
    try {
      // WhatsApp video call link - you can change this URL as needed
      const whatsappLink = 'https://call.whatsapp.com/video/Rl2Y8a8WIrNkgf9jR4wuOw';
      
      final Uri url = Uri.parse(whatsappLink);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print('✅ WhatsApp video call launched successfully');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp video call...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ Could not launch WhatsApp video call');
        _showErrorSnackBar('Could not open WhatsApp video call. Please make sure WhatsApp is installed.');
      }
    } catch (e) {
      print('❌ Error launching video call: $e');
      _showErrorSnackBar('Error launching video call: $e');
    }
  }

  Future<void> _startVoiceDictation() async {
    try {
      // Get doctor_id from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final doctorId = authProvider.patientId; // doctor_id is stored in patientId field
      
      if (doctorId == null || doctorId.isEmpty) {
        _showErrorSnackBar('Doctor ID not found. Please login again.');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Starting voice dictation...'),
            ],
          ),
        ),
      );

      // Create a new voice conversation
      final conversationData = {
        'patient_id': doctorId, // Using doctor_id as patient_id for voice conversations
        'title': 'Voice Dictation Session',
        'language': 'en',
        'is_active': true,
        'duration_seconds': 0.0,
      };

      final response = await _apiService.createVoiceConversation(conversationData);
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (response.containsKey('error')) {
        _showErrorSnackBar('Failed to start voice dictation: ${response['error']}');
        return;
      }

      final conversationId = response['conversation_id'];
      
      // Show success message and navigate to voice dictation screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice dictation started! Conversation ID: $conversationId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // TODO: Navigate to voice dictation screen
      // For now, show a dialog with conversation details
      _showVoiceDictationDialog(conversationId, response['conversation']);

    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('❌ Error starting voice dictation: $e');
      _showErrorSnackBar('Error starting voice dictation: $e');
    }
  }

  void _showVoiceDictationDialog(String conversationId, Map<String, dynamic> conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Dictation Started'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conversation ID: $conversationId'),
            const SizedBox(height: 8),
            Text('Title: ${conversation['title']}'),
            const SizedBox(height: 8),
            Text('Language: ${conversation['language']}'),
            const SizedBox(height: 8),
            Text('Status: ${conversation['is_active'] ? 'Active' : 'Inactive'}'),
            const SizedBox(height: 16),
            const Text(
              'Voice dictation is ready! You can now start recording audio and it will be transcribed in real-time.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to enhanced voice recording screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SimpleVoiceRecordingScreen(
                    conversationId: conversationId,
                    conversationTitle: conversation['title'],
                  ),
                ),
              );
            },
            child: const Text('Start Recording'),
          ),
        ],
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildClickableStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
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

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }
}

                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
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

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }
}

                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
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

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }
}
