import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String role;
  
  const ForgotPasswordScreen({
    super.key,
    this.role = 'patient',
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdentifierController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _userEmail;

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.forgotPassword(
      loginIdentifier: _loginIdentifierController.text.trim(),
      role: widget.role,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      setState(() {
        _otpSent = true;
        _userEmail = _loginIdentifierController.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to send OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.forgotPasswordTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Icon and Title
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.forgotPasswordTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.role == 'doctor' 
                    ? 'Enter your Doctor ID or Email to receive a password reset OTP'
                    : 'Enter your Patient ID or Email to receive a password reset OTP',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Login Identifier Input
                CustomTextField(
                  controller: _loginIdentifierController,
                  labelText: widget.role == 'doctor' ? 'Doctor ID or Email' : 'Patient ID or Email',
                  hintText: widget.role == 'doctor' ? 'Enter your Doctor ID or Email' : 'Enter your Patient ID or Email',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return widget.role == 'doctor' 
                        ? 'Please enter your Doctor ID or Email'
                        : 'Please enter your Patient ID or Email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Send OTP Button
                LoadingButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  isLoading: _isLoading,
                  text: 'Send Reset OTP',
                ),
                const SizedBox(height: 16),

                // OTP Sent Message
                if (_otpSent)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'OTP sent successfully!',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check your email for the OTP code',
                          style: TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/reset-password',
                              arguments: {
                                'email': _userEmail,
                                'role': widget.role,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          child: const Text('Enter OTP'),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Back to Login
                TextButton(
                  onPressed: () {
                    // Navigate to appropriate login page based on role
                    if (widget.role == 'doctor') {
                      Navigator.pushReplacementNamed(context, '/login', arguments: 'doctor');
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text(
                    'Back to Login',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 