import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addAppointment,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.textSecondary,
            ),
          SizedBox(height: 16),
          Text(
            'Appointments',
              style: TextStyle(
              fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
          SizedBox(height: 8),
                      Text(
            'No appointments scheduled',
                    style: TextStyle(
                        color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'This feature is coming soon!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _addAppointment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add appointment feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}