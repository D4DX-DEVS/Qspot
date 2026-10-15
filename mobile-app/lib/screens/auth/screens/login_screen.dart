import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/registered_account.dart';
import '../provider/auth_provider.dart';
import '../provider/login_form_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../widgets/arch_header.dart';
import '../widgets/art/auth_art.dart';
import '../widgets/art/mosque_skyline_painter.dart';
import '../widgets/auth_brand_mark.dart';
import '../widgets/auth_dob_picker.dart';
import '../widgets/auth_headline.dart';
import '../widgets/auth_link_row.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_theme_scope.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/gradient_pill_button.dart';
import 'registration_screen.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../../faculty/screens/faculty_home_screen.dart';

/// Sign-in screen: phone number + date of birth.
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginFormProvider _form = LoginFormProvider();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() => _form.setPhone(_phoneController.text);

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _form.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showAuthDobPicker(context, initial: _form.dob);
    if (picked != null && mounted) {
      _form.setDob(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artHeight = (MediaQuery.sizeOf(context).height * 0.3).clamp(
      170.0,
      280.0,
    );
    return ChangeNotifierProvider.value(
      value: _form,
      child: Consumer<LoginFormProvider>(
        builder: (_, form, __) => _buildPage(form, artHeight),
      ),
    );
  }

  Widget _buildPage(LoginFormProvider form, double artHeight) {
    return AuthThemeScope(
      child: AuthPageLayout(
        bottomArt: const AuthArt(painter: MosqueSkylinePainter.new),
        bottomArtHeight: artHeight,
        // The top of the scene is sky, so the links may sit over it.
        bottomArtOverlap: artHeight * 0.4,
        centerContent: true,
        children: [
          const StaggeredEntrance(
            index: 0,
            child: ArchHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBrandMark(size: 150),
                  AuthHeadline(
                    title: 'Learn the ',
                    accent: 'Qur’ān',
                    trailing: ',\none episode at a time.',
                    subtitle:
                        'Sign in with your phone number and date of birth to continue.',
                    textAlign: TextAlign.center,
                    fontSize: 26,
                    subtitleFontSize: 13.5,
                  ),
                ],
              ),
            ),
          ),
          StaggeredEntrance(
            index: 1,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthPhoneField(controller: _phoneController),
                  const SizedBox(height: 14),
                  DatePickerField(
                    hint: 'Date of Birth',
                    valueText: form.dobForApi,
                    onTap: _pickDob,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          StaggeredEntrance(
            index: 2,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) => GradientPillButton(
                label: 'Sign In',
                isLoading: authProvider.isLoading,
                onPressed: form.isComplete && !authProvider.isLoading
                    ? _signIn
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          StaggeredEntrance(
            index: 3,
            child: AuthLinkRow(
              prompt: "Don't Have an Account?",
              action: 'Register Now',
              onTap: _navigateToRegistration,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final dob = _form.dobForApi;
    if (dob == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Send only 10 digits without country code to match registration format
    final phone = _phoneController.text.trim();

    final result = await authProvider.login(phone, dob);

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
            'We couldn\'t sign you in. Please check your details and try again.',
        color: AppColors.danger,
      );
    }
  }

  Future<void> _navigateToRegistration() async {
    final registered = await Navigator.of(context).push<RegisteredAccount>(
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );

    if (!mounted || registered == null) return;

    // Registration never authenticates the user (no token is returned), so
    // sign the new account in with the number and date of birth they just
    // registered with.
    _phoneController.text = registered.phone;
    _form.setDob(registered.dob);
    await _signIn();
  }
}
