import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../services/course_service.dart';

/// Create-account form. Same flat pattern as the sign-in screen: a circular
/// back button, one bold heading, soft filled fields, and a single full-width
/// pill action that stays disabled until the form is complete.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _consentNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
    for (final controller in [
      _phoneController,
      _nameController,
      _classController,
    ]) {
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
    for (final controller in [
      _phoneController,
      _nameController,
      _classController,
    ]) {
      controller.removeListener(_onFieldChanged);
      controller.dispose();
    }
    _consentNameController.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _phoneController.text.trim().length == 10 &&
      _nameController.text.trim().length >= 3 &&
      _classController.text.trim().isNotEmpty;

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
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _backButton(),
                    const SizedBox(height: 28),
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your number signs you in, so there is no password to remember.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'Phone number',
                        prefixText: '+91  ',
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.trim().length != 10) {
                          return 'Please enter a valid 10 digit mobile number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'Full name',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _classController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'Class (for example 9, 10, 11)',
                        prefixIcon: const Icon(
                          Icons.school_outlined,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your class';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _coursePicker(),
                    const SizedBox(height: 16),
                    _dobField(),
                    const SizedBox(height: 16),
                    _consentSection(),
                    const SizedBox(height: 28),
                    _submitButton(),
                    const SizedBox(height: 16),
                    const Text(
                      'We only use your number to sign you in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
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

  Widget _coursePicker() {
    if (_coursesLoading) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: LinearProgressIndicator(minHeight: 3),
        ),
      );
    }
    if (_courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your courses',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'You can choose more than one and change this later.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _courses.length; i++) ...[
                CheckboxListTile(
                  value: _selectedCourseIds.contains(_courses[i].id),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _selectedCourseIds.add(_courses[i].id);
                    } else {
                      _selectedCourseIds.remove(_courses[i].id);
                    }
                  }),
                  title: Text(_courses[i].title),
                  subtitle: _courses[i].subtitle.isEmpty
                      ? null
                      : Text(_courses[i].subtitle),
                  activeColor: AppTheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                if (i < _courses.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _dobField() {
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _fieldDecoration(
          hint: 'Date of birth (optional)',
          prefixIcon: const Icon(
            Icons.cake_outlined,
            color: AppTheme.textMuted,
            size: 20,
          ),
        ),
        child: Text(
          _dob != null ? _formatDob(_dob!) : 'Date of birth (optional)',
          style: TextStyle(
            color: _dob != null ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: _dob != null ? 16 : 15,
          ),
        ),
      ),
    );
  }

  Widget _consentSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            value: _hasConsent,
            onChanged: (value) => setState(() => _hasConsent = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.primary,
            title: const Text(
              'A parent/guardian or school has given consent',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
          if (_hasConsent) ...[
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'parent',
                    groupValue: _consentBy,
                    onChanged: (value) =>
                        setState(() => _consentBy = value ?? 'parent'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                    title: const Text('Parent', style: TextStyle(fontSize: 13)),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'school',
                    groupValue: _consentBy,
                    onChanged: (value) =>
                        setState(() => _consentBy = value ?? 'parent'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                    title: const Text('School', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _consentNameController,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: _fieldDecoration(
                  hint: _consentBy == 'parent'
                      ? "Parent/guardian's name"
                      : "School name",
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
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

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefixIcon,
    String? prefixText,
  }) {
    final radius = BorderRadius.circular(14);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
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

  Widget _submitButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final enabled = _isComplete && !authProvider.isLoading;
        return SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              disabledBackgroundColor: AppTheme.surfaceAlt,
              disabledForegroundColor: AppTheme.textMuted,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: enabled ? _register : null,
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onPrimary,
                    ),
                  )
                : const Text('Create account'),
          ),
        );
      },
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
      classNumber: _classController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Registration successful! Enter the OTP to continue.',
            style: const TextStyle(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );

      // Registration does not return a token - hand the phone number back
      // to the login screen so it can request an OTP straight away.
      Navigator.pop(context, phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Registration failed',
            style: const TextStyle(color: AppTheme.onPrimary),
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }
}
