import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../widgets/common/otp_input.dart';
import '../widgets/arch_header.dart';
import '../widgets/art/auth_art.dart';
import '../widgets/art/mosque_skyline_painter.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_brand_mark.dart';
import '../widgets/auth_headline.dart';
import '../widgets/auth_link_row.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_theme_scope.dart';
import '../widgets/gradient_pill_button.dart';
import 'registration_screen.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../../faculty/screens/faculty_home_screen.dart';

/// Sign-in screen: phone number -> WhatsApp OTP.
///
/// Logo and headline sit inside a pointed arch over a mosque skyline; light
/// or dark follows the phone's setting (see [AuthThemeScope]).
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
    final artHeight = (MediaQuery.sizeOf(context).height * 0.3).clamp(
      170.0,
      280.0,
    );
    return AuthThemeScope(
      child: AuthPageLayout(
        bottomArt: const AuthArt(painter: MosqueSkylinePainter.new),
        bottomArtHeight: artHeight,
        // The top of the scene is sky, so the links may sit over it.
        bottomArtOverlap: artHeight * 0.4,
        children: [
          ArchHeader(
            // Back arrow only after the code has been requested, so the
            // student can correct a mistyped number.
            leading: _otpSent
                ? AuthBackButton(
                    onPressed: () => setState(() {
                      _otpSent = false;
                      _otpController.clear();
                    }),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthBrandMark(size: 150),
                _otpSent
                    ? AuthHeadline(
                        title: 'Check your ',
                        accent: 'WhatsApp',
                        subtitle:
                            'Enter the 6-digit code we sent to ${_phoneController.text}',
                        textAlign: TextAlign.center,
                        fontSize: 26,
                      )
                    : const AuthHeadline(
                        title: 'Learn the ',
                        accent: 'Qur’ān',
                        trailing: ',\none episode at a time.',
                        subtitle:
                            'Sign in with your phone number to continue.\nWe will send a one-time code to your WhatsApp.',
                        textAlign: TextAlign.center,
                        fontSize: 26,
                        subtitleFontSize: 13.5,
                      ),
              ],
            ),
          ),
          Form(
            key: _formKey,
            child: _otpSent
                ? _otpField()
                : AuthPhoneField(controller: _phoneController),
          ),
          const SizedBox(height: 20),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) => GradientPillButton(
              label: _otpSent ? 'Verify OTP' : 'Send OTP',
              isLoading: authProvider.isLoading,
              onPressed: authProvider.isLoading
                  ? null
                  : (_otpSent ? _verifyOtp : _sendOtp),
            ),
          ),
          const SizedBox(height: 16),
          if (_otpSent)
            Builder(
              builder: (context) => Text(
                'Didn’t get the code? Tap Resend, or go back and check your number.',
                textAlign: TextAlign.center,
                style: AppFonts.regular(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            )
          else
            AuthLinkRow(
              prompt: "Don't have an account?",
              action: 'Register Now',
              onTap: _navigateToRegistration,
            ),
        ],
      ),
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
        const SizedBox(height: 10),
        AuthLinkRow(
          prompt: 'Didn’t receive OTP?',
          action: _isResending ? 'Resending…' : 'Resend',
          onTap: _isResending ? null : _resendOtp,
          showChevron: false,
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

      AppSnackBar.show(
        context,
        message: 'We\'ve sent a 6-digit OTP to your WhatsApp',
        color: AppColors.success,
      );
    } else {
      AppSnackBar.show(
        context,
        message:
            result['message'] ??
            'We couldn\'t send the OTP. Please try again.',
        color: AppColors.danger,
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
      AppSnackBar.show(
        context,
        message: 'Please enter all 6 digits of the OTP',
        color: AppColors.warningOrange,
      );
      return;
    }

    final result = await authProvider.verifyOtp(phone, otp);

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => authProvider.user?.role == 'faculty'
              ? const FacultyHomeScreen()
              : const MainNavigationScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } else {
      AppSnackBar.show(
        context,
        message:
            result['message'] ??
            'That OTP didn\'t work. Please check it and try again.',
        color: AppColors.danger,
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
