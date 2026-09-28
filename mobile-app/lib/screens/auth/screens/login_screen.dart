import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/otp_input.dart';
import 'registration_screen.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../../faculty/screens/faculty_home_screen.dart';

/// Sign-in screen: phone number -> WhatsApp OTP.
///
/// Layout follows the flat, centred pattern used by the apps we took as
/// reference: circular brand mark, one bold headline, soft filled inputs and a
/// single full-width pill action per step.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _isResending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            // Keeps the column phone-shaped on tablets and desktop instead of
            // stretching the pill buttons across the whole window.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back arrow only after the code has been requested, so the
                    // student can correct a mistyped number.
                    if (_otpSent) _backButton() else const SizedBox(height: 44),
                    const SizedBox(height: 28),
                    _brandMark(),
                    const SizedBox(height: 36),
                    Text(
                      _otpSent
                          ? 'Check your WhatsApp'
                          : 'Learn the Qur’ān,\none episode at a time.',
                      textAlign: TextAlign.center,
                      style: AppFonts.bold(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _otpSent
                          ? 'Enter the 6-digit code we sent to ${_phoneController.text}'
                          : 'Sign in with your phone number to continue.',
                      textAlign: TextAlign.center,
                      style: AppFonts.regular(
                        color: AppTheme.textMuted,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (!_otpSent) _phoneField() else _otpField(),
                    const SizedBox(height: 24),
                    _primaryButton(),
                    const SizedBox(height: 16),
                    Text(
                      _otpSent
                          ? 'Didn’t get the code? Tap Resend, or go back and check your number.'
                          : 'We will send a one-time code to your WhatsApp.',
                      textAlign: TextAlign.center,
                      style: AppFonts.regular(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (!_otpSent) _registerRow(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandMark() {
    return Center(
      child: Container(
        width: 176,
        height: 176,
        padding: const EdgeInsets.all(26),
        decoration: const BoxDecoration(
          color: AppTheme.primarySoft,
          shape: BoxShape.circle,
        ),
        // qspot-mark.png is Icon.png cropped to a tight square around the mark.
        child: Image.asset('assets/icons/qspot-mark.png', fit: BoxFit.contain),
      ),
    );
  }

  Widget _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => setState(() {
          _otpSent = false;
          _otpController.clear();
        }),
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _phoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: AppFonts.regular(color: AppTheme.textPrimary, fontSize: 16),
      decoration: _fieldDecoration(
        hint: 'Phone number',
        prefixIcon: const Icon(
          Icons.phone_outlined,
          color: AppTheme.textMuted,
          size: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        }
        if (value.length != 10) {
          return 'Please enter a valid 10-digit phone number';
        }
        return null;
      },
    );
  }

  Widget _otpField() {
    return Column(
      children: [
        OtpInput(
          controller: _otpController,
          length: 6,
          onCompleted: (_) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (!auth.isLoading) _verifyOtp();
          },
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn’t receive OTP?',
              style: AppFonts.regular(color: AppTheme.textMuted, fontSize: 14),
            ),
            TextButton(
              onPressed: _isResending ? null : _resendOtp,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isResending ? 'Resending…' : 'Resend',
                style: AppFonts.bold(
                  color: AppTheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({required String hint, Widget? prefixIcon}) {
    final radius = BorderRadius.circular(14);
    return InputDecoration(
      hintText: hint,
      hintStyle: AppFonts.regular(color: AppTheme.textMuted, fontSize: 15),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppTheme.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppTheme.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppTheme.danger, width: 1.6),
      ),
    );
  }

  Widget _primaryButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              disabledBackgroundColor: AppTheme.primary,
              disabledForegroundColor: AppTheme.onPrimary,
              shape: const StadiumBorder(),
              textStyle: AppFonts.bold(
                fontSize: 16,
              ),
            ),
            onPressed: authProvider.isLoading
                ? null
                : (_otpSent ? _verifyOtp : _sendOtp),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onPrimary,
                    ),
                  )
                : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
          ),
        );
      },
    );
  }

  Widget _registerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: AppFonts.regular(color: AppTheme.textMuted, fontSize: 15),
        ),
        TextButton(
          onPressed: _navigateToRegistration,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Register Now',
            style: AppFonts.bold(
              color: AppTheme.primary,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Send only 10 digits without country code to match registration format
    final phone = _phoneController.text.trim();

    final result = await authProvider.requestOtp(phone);

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'OTP sent successfully via WhatsApp',
            style: AppFonts.regular(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Failed to send OTP',
            style: AppFonts.regular(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Send only 10 digits without country code to match registration format
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    // The six-box OTP field has no FormField validator, so check it here.
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the 6-digit OTP',
            style: AppFonts.regular(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final result = await authProvider.verifyOtp(phone, otp);

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => authProvider.user?.role == 'faculty'
            ? const FacultyHomeScreen()
            : const MainNavigationScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Invalid OTP',
            style: AppFonts.regular(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    await _sendOtp();

    setState(() {
      _isResending = false;
    });
  }

  Future<void> _navigateToRegistration() async {
    final registeredPhone = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );

    if (!mounted) return;

    // Registration never authenticates the user (no token is returned), so
    // on success we drop the student straight into the OTP step for the
    // number they just registered with.
    if (registeredPhone != null && registeredPhone.isNotEmpty) {
      setState(() {
        _phoneController.text = registeredPhone;
      });
      await _sendOtp();
    }
  }
}
