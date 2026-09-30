import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_fonts.dart';
import '../../../services/course_service.dart';
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

  String? _classNumber;
  DateTime? _dob;
  bool _hasConsent = false;
  String _consentBy = 'parent';
  List<CourseModel> _courses = const [];
  final Set<String> _selectedCourseIds = <String>{};
  bool _coursesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    for (final controller in [_phoneController, _nameController]) {
      controller.addListener(_onFieldChanged);
    }
  }

  Future<void> _loadCourses() async {
    final courses = await CourseService.fetchActive();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _coursesLoading = false;
    });
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final controller in [_phoneController, _nameController]) {
      controller.removeListener(_onFieldChanged);
      controller.dispose();
    }
    _consentNameController.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _phoneController.text.trim().length == 10 &&
      _nameController.text.trim().length >= 3 &&
      _classNumber != null;

  String _formatDob(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 12, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      // This context sits above the page's AuthThemeScope, so re-apply it.
      builder: (context, child) => AuthThemeScope(child: child!),
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Stack(
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
          const AuthHeadline(
            title: 'Create your ',
            accent: 'account',
            subtitle:
                'Your number signs you in, so there is no password to remember.',
            fontSize: 28,
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthPhoneField(
                  controller: _phoneController,
                  hint: 'Phone number',
                  showPhoneIcon: true,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _nameController,
                  hint: 'Full name',
                  icon: Icons.person_outline_rounded,
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
                const SizedBox(height: 14),
                ClassDropdownField(
                  value: _classNumber,
                  onChanged: (value) => setState(() => _classNumber = value),
                ),
                const SizedBox(height: 14),
                CoursePickerCard(
                  courses: _courses,
                  selectedIds: _selectedCourseIds,
                  isLoading: _coursesLoading,
                  onToggle: (id, selected) => setState(() {
                    if (selected) {
                      _selectedCourseIds.add(id);
                    } else {
                      _selectedCourseIds.remove(id);
                    }
                  }),
                ),
                if (_coursesLoading || _courses.isNotEmpty)
                  const SizedBox(height: 14),
                DatePickerField(
                  hint: 'Date of birth (optional)',
                  valueText: _dob != null ? _formatDob(_dob!) : null,
                  onTap: _pickDob,
                ),
                const SizedBox(height: 14),
                ConsentCard(
                  value: _hasConsent,
                  onChanged: (value) => setState(() => _hasConsent = value),
                  consentBy: _consentBy,
                  onConsentByChanged: (by) => setState(() => _consentBy = by),
                  nameController: _consentNameController,
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) => GradientPillButton(
                    label: 'Create account',
                    isLoading: authProvider.isLoading,
                    onPressed: _isComplete && !authProvider.isLoading
                        ? _register
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
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
      classNumber: _classNumber!,
      dob: _dob != null ? _formatDob(_dob!) : null,
      consent: _hasConsent
          ? {
              'by': _consentBy,
              if (_consentNameController.text.trim().isNotEmpty)
                'name': _consentNameController.text.trim(),
            }
          : null,
      courseIds: _selectedCourseIds.toList(),
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
