import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../model/phone_country.dart';
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
import '../widgets/auth_text_field.dart';
import '../widgets/auth_theme_scope.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/gradient_pill_button.dart';
import 'registration_screen.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../../faculty/screens/faculty_home_screen.dart';

/// Sign-in screen: name + phone number for students, phone number + date of
/// birth for teachers. "Sign In" can always be tapped: what is missing or
/// wrong then shows under its field.
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
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LoginFormProvider _form = LoginFormProvider();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    _nameController.addListener(_onNameChanged);
  }

  void _onPhoneChanged() => _form.setPhone(_phoneController.text);

  void _onNameChanged() => _form.setName(_nameController.text);

  /// A number typed for the old country is cut to fit the new one.
  void _onCountryChanged(PhoneCountry country) {
    _form.setCountry(country);
    final cleaned = country.cleanNumber(_phoneController.text);
    if (cleaned != _phoneController.text) _phoneController.text = cleaned;
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.removeListener(_onNameChanged);
    _phoneController.dispose();
    _nameController.dispose();
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
          StaggeredEntrance(
            index: 0,
            child: ArchHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthBrandMark(size: 150),
                  AuthHeadline(
                    title: 'Learn the ',
                    accent: 'Qur’ān',
                    trailing: ',\none episode at a time.',
                    subtitle: form.isTeacher
                        ? 'Sign in with your phone number and date of birth to continue.'
                        : 'Sign in with your name and phone number to continue.',
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
              // After the first tap on "Sign In", errors follow the typing.
              autovalidateMode: form.submitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!form.isTeacher) ...[
                    AuthTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: LucideIcons.userRound,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  AuthPhoneField(
                    controller: _phoneController,
                    country: form.country,
                    onCountryChanged: _onCountryChanged,
                  ),
                  if (form.isTeacher) ...[
                    const SizedBox(height: 14),
                    DatePickerField(
                      hint: 'Date of Birth',
                      valueText: form.dobForApi,
                      onTap: _pickDob,
                      errorText: form.dobError,
                    ),
                  ],
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
                onPressed: _signIn,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Only students register, so a teacher sees just the way back.
          if (!form.isTeacher)
            StaggeredEntrance(
              index: 3,
              child: AuthLinkRow(
                prompt: "Don't Have an Account?",
                action: 'Register Now',
                onTap: _navigateToRegistration,
              ),
            ),
          StaggeredEntrance(
            index: 4,
            child: AuthLinkRow(
              prompt: form.isTeacher ? 'Student?' : 'Teacher?',
              action: form.isTeacher
                  ? 'Sign in with name'
                  : 'Sign in with date of birth',
              onTap: form.toggleTeacher,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    _form.markSubmitted();
    if (!_formKey.currentState!.validate()) return;
    await _submit();
  }

  /// Sends whichever of name or date of birth is on screen; the other one is
  /// always null (see [LoginFormProvider.nameForApi]).
  Future<void> _submit() async {
    if (!_form.isComplete) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(
      _form.phoneForApi,
      name: _form.nameForApi,
      dob: _form.dobForApi,
    );

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
    // sign the new account in with the name and number they just registered
    // with. Registration already checked both, so the form is not validated
    // again here.
    _form.setCountry(registered.country);
    _nameController.text = registered.name;
    _phoneController.text = registered.phone;
    await _submit();
  }
}
