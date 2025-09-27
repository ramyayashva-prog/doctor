import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String role;
  
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCount = 0;
  DateTime? _lastResendTime;
  Timer? _resendTimer;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(
      email: widget.email,
      otp: _otpCode,
      role: widget.role,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      if (widget.role == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor-profile-completion');
      } else {
        Navigator.pushReplacementNamed(context, '/profile-completion');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'OTP verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    // Check if resend is allowed (max 3 times, 30 seconds cooldown)
    if (_resendCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum resend attempts reached. Please try again later.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_lastResendTime != null) {
      final timeSinceLastResend = DateTime.now().difference(_lastResendTime!);
      if (timeSinceLastResend.inSeconds < 30) {
        final remainingTime = 30 - timeSinceLastResend.inSeconds;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait $remainingTime seconds before resending.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isResending = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.resendOtp(
      email: widget.email,
      role: widget.role,
    );

    setState(() {
      _isResending = false;
      _resendCount++;
      _lastResendTime = DateTime.now();
    });

    // Start timer to update button text
    _startResendTimer();

    if (mounted) {
      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP: ${response['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP resent successfully! (${_resendCount}/3 attempts)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  bool get _canResend {
    if (_resendCount >= 3) return false;
    if (_lastResendTime == null) return true;
    final timeSinceLastResend = DateTime.now().difference(_lastResendTime!);
    return timeSinceLastResend.inSeconds >= 30;
  }

  String get _resendButtonText {
    if (_resendCount >= 3) return 'Max attempts reached';
    if (_lastResendTime == null) return 'Resend OTP';
    final timeSinceLastResend = DateTime.now().difference(_lastResendTime!);
    if (timeSinceLastResend.inSeconds < 30) {
      final remainingTime = 30 - timeSinceLastResend.inSeconds;
      return 'Resend OTP ($remainingTime)';
    }
    return 'Resend OTP';
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
        if (_canResend) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.otpTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Icon and Title
              Icon(
                Icons.verified_user,
                size: 70,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.otpTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.otpSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Email: ${widget.email}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onOtpChanged(value, index),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Verify Button
              LoadingButton(
                onPressed: _isLoading ? null : _verifyOtp,
                isLoading: _isLoading,
                text: AppStrings.verifyOtp,
              ),
              const SizedBox(height: 16),

              // Resend OTP
              TextButton(
                onPressed: (_isLoading || _isResending || !_canResend) ? null : _resendOtp,
                child: _isResending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Resending...'),
                        ],
                      )
                    : Text(
                        _resendButtonText,
                        style: TextStyle(
                          color: _canResend ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
              ),
              
              // Extra space at bottom to prevent overflow
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
} 