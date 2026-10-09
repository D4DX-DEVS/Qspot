import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../provider/registration_form_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../widgets/art/auth_art.dart';
import '../widgets/art/bottom_waves_painter.dart';
import '../widgets/art/corner_wave_painter.dart';
import '../widgets/art/mosque_skyline_painter.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_brand_mark.dart';
import '../widgets/auth_headline.dart';
import '../widgets/auth_page_layout.dart';
import '../widgets/auth_phone_field.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_theme_scope.dart';
import '../widgets/class_dropdown_field.dart';
import '../widgets/consent_card.dart';
import '../widgets/course_picker_card.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/gradient_pill_button.dart';

/// Create-account form: back button, logo, one bold heading, themed fields
/// and a gradient pill that stays faded until the form is complete. Light or
/// dark follows the phone's setting (see [AuthThemeScope]).
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _consentNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final RegistrationFormProvider _form = RegistrationFormProvider();

  @override
  void initState() {
    super.initState();
    _form.loadCourses();
    _phoneController.addListener(_onPhoneChanged);
    _nameController.addListener(_onNameChanged);
  }

  void _onPhoneChanged() => _form.setPhone(_phoneController.text);

  void _onNameChanged() => _form.setName(_nameController.text);

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.removeListener(_onNameChanged);
    _phoneController.dispose();
    _nameController.dispose();
    _consentNameController.dispose();
    _form.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _form.dob ?? DateTime(now.year - 12, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      // Opens on the year list so a teen taps their birth year first.
      initialDatePickerMode: DatePickerMode.year,
      // This context sits above the page's AuthThemeScope, so re-apply it.
      builder: (context, child) => AuthThemeScope(child: child!),
    );
    if (picked != null && mounted) {
      _form.setDob(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _form,
      child: Consumer<RegistrationFormProvider>(
        builder: (_, form, __) => _buildPage(form),
      ),
    );
  }

  Widget _buildPage(RegistrationFormProvider form) {
    return AuthThemeScope(
      child: AuthPageLayout(
        topArt: const AuthArt(painter: CornerWavePainter.new),
        topArtHeight: 230,
        bottomArt: AuthArt(
          painter: (palette) => palette.isDark
              ? MosqueSkylinePainter(palette, showBookStand: false)
              : BottomWavesPainter(palette),
        ),
        bottomArtHeight: 120,
        children: [
          StaggeredEntrance(
            index: 0,
            child: Stack(
              children: [
                const AuthBrandMark(size: 116),
                Positioned(
                  top: 0,
                  left: 0,
                  child: AuthBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          const StaggeredEntrance(
            index: 1,
            child: AuthHeadline(
              title: 'Create Your ',
              accent: 'Account',
              subtitle:
                  'Your number signs you in, so there is no password to remember.',
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaggeredEntrance(
                  index: 2,
                  child: AuthPhoneField(
                    controller: _phoneController,
                    hint: 'Phone Number',
                    showPhoneIcon: true,
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEntrance(
                  index: 3,
                  child: AuthTextField(
                    controller: _nameController,
                    hint: 'Full Name',
                    icon: LucideIcons.userRound,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEntrance(
                  index: 4,
                  child: ClassDropdownField(
                    value: form.classNumber,
                    onChanged: form.setClassNumber,
                  ),
                ),
                const SizedBox(height: 14),
                CoursePickerCard(
                  courses: form.courses,
                  selectedIds: form.selectedCourseIds,
                  isLoading: form.coursesLoading,
                  onToggle: form.toggleCourse,
                ),
                if (form.coursesLoading || form.courses.isNotEmpty)
                  const SizedBox(height: 14),
                StaggeredEntrance(
                  index: 5,
                  child: DatePickerField(
                    hint: 'Date of Birth (Optional)',
                    valueText: form.dob != null
                        ? form.formatDob(form.dob!)
                        : null,
                    onTap: _pickDob,
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredEntrance(
                  index: 6,
                  child: ConsentCard(
                    value: form.hasConsent,
                    onChanged: form.setHasConsent,
                    consentBy: form.consentBy,
                    onConsentByChanged: form.setConsentBy,
                    nameController: _consentNameController,
                  ),
                ),
                const SizedBox(height: 24),
                StaggeredEntrance(
                  index: 7,
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) =>
                        GradientPillButton(
                          label: 'Create Account',
                          isLoading: authProvider.isLoading,
                          onPressed: form.isComplete && !authProvider.isLoading
                              ? _register
                              : null,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                StaggeredEntrance(
                  index: 7,
                  child: Builder(
                    builder: (context) => Text(
                      'We only use your number to sign you in.',
                      textAlign: TextAlign.center,
                      style: AppFonts.regular(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Remove any country code or non-digit characters, send only 10 digits
    String phone = _phoneController.text.trim().replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    if (phone.startsWith('91') && phone.length > 10) {
      phone = phone.substring(2); // Remove country code if present
    }

    final result = await authProvider.register(
      phone: phone,
      name: _nameController.text.trim(),
      classNumber: _form.classNumber!,
      dob: _form.dob != null ? _form.formatDob(_form.dob!) : null,
      consent: _form.hasConsent
          ? {
              'by': _form.consentBy,
              if (_consentNameController.text.trim().isNotEmpty)
                'name': _consentNameController.text.trim(),
            }
          : null,
      courseIds: _form.selectedCourseIds.toList(),
    );

    if (!mounted) return;

    if (result['success']) {
      AppSnackBar.show(
        context,
        message: 'Your account is ready! Sending your OTP now…',
        color: AppColors.success,
      );

      // Registration does not return a token - hand the phone number back
      // to the login screen so it can request an OTP straight away.
      Navigator.pop(context, phone);
    } else {
      AppSnackBar.show(
        context,
        message:
            result['message'] ??
            'We couldn\'t create your account. Please try again.',
        color: AppColors.danger,
      );
    }
  }
}
