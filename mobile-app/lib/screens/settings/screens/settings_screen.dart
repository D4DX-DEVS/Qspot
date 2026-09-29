import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../common/screens/contact_us_screen.dart';
import '../../question/screens/ask_question_screen.dart';
import '../../question/screens/my_questions_screen.dart';
import '../../speaker/screens/faculties_screen.dart';
import '../../schedule/service/alarm_service.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../services/session.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AlarmService _alarmService = AlarmService();
  bool _alarmEnabled = false;
  int _alarmHour = 18;
  int _alarmMinute = 50;
  bool _isLoading = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAlarmSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _loadAlarmSettings() async {
    try {
      final isEnabled = await _alarmService.isAlarmEnabled();
      final time = await _alarmService.getSavedAlarmTime();

      setState(() {
        _alarmEnabled = isEnabled;
        _alarmHour = time['hour']!;
        _alarmMinute = time['minute']!;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading alarm settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Settings'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              children: [
                // Who is signed in
                _buildProfileCard(context),
                const SizedBox(height: AppTheme.paddingLarge),

                // Notifications Section
                _buildSectionHeader(context, 'Notifications'),
                const SizedBox(height: AppTheme.paddingSmall),
                _buildAlarmSettingsCard(context),
                const SizedBox(height: AppTheme.paddingLarge),

                // App Info Section
                _buildSectionHeader(context, 'App Information'),
                const SizedBox(height: AppTheme.paddingSmall),

                _buildSettingsItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About Us',
                  subtitle: 'Learn more about D4DX Innovations',
                  onTap: () => _launchUrl('https://d4dx.co/about-us/'),
                ),

                _buildSettingsItem(
                  context: context,
                  icon: Icons.contact_support,
                  title: 'Contact Us',
                  subtitle: 'Get in touch with our team',
                  onTap: () => _navigateToContactUs(context),
                ),

                _buildSettingsItem(
                  context: context,
                  icon: Icons.groups_outlined,
                  title: 'Faculties',
                  subtitle: 'Meet the scholars behind the episodes',
                  onTap: () => _navigateToFaculties(context),
                ),

                _buildSettingsItem(
                  context: context,
                  icon: Icons.question_answer,
                  title: 'Ask a Question',
                  subtitle: 'Ask questions to our faculties',
                  onTap: () => _showAskQuestionDialog(context),
                ),

                _buildSettingsItem(
                  context: context,
                  icon: Icons.history,
                  title: 'My Questions',
                  subtitle: 'View your questions and answers',
                  onTap: () => _navigateToMyQuestions(context),
                ),

                _buildSettingsItem(
                  context: context,
                  icon: Icons.feedback,
                  title: 'Feedback',
                  subtitle: 'Share your thoughts and suggestions',
                  onTap: () => _sendFeedback(context),
                ),

                _buildSettingsItem(
                  context: context,
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy and data policy',
                  onTap: () => _launchUrl('https://d4dx.co/privacy-policy/'),
                ),

                const SizedBox(height: AppTheme.paddingLarge),

                // Logout Section
                _buildLogoutButton(context),

                const SizedBox(height: AppTheme.paddingLarge),

                // App Details Section
                _buildSectionHeader(context, 'App Details'),
                const SizedBox(height: AppTheme.paddingSmall),

                _buildInfoCard(context),

                const SizedBox(height: AppTheme.paddingLarge),

                // Footer
                _buildFooter(context),
              ],
            ),
    );
  }

  Widget _buildAlarmSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alarm Toggle
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.alarm,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Reminder',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get notified to watch videos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _alarmEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Request permissions first
                    final hasPermission = await _alarmService
                        .requestPermissions();
                    if (!hasPermission) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Notification permission denied',
                            ),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    // Schedule alarm
                    final success = await _alarmService.scheduleAlarm(
                      _alarmHour,
                      _alarmMinute,
                    );

                    if (success && context.mounted) {
                      setState(() {
                        _alarmEnabled = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Daily reminder set for ${_formatTime(_alarmHour, _alarmMinute)}',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                        ),
                      );
                    }
                  } else {
                    // Cancel alarm
                    await _alarmService.cancelAlarm();
                    setState(() {
                      _alarmEnabled = false;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Daily reminder disabled'),
                          backgroundColor: AppColors.textPrimary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primarySoft,
              ),
            ],
          ),

          // Time Picker (always show, but only editable when alarm is enabled)
          const SizedBox(height: AppTheme.paddingMedium),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppTheme.paddingMedium),
          InkWell(
            onTap: _alarmEnabled ? () => _showTimePicker(context) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: _alarmEnabled
                    ? AppColors.surfaceAlt
                    : AppColors.surfaceAlt.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: _alarmEnabled
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Time',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(_alarmHour, _alarmMinute),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: _alarmEnabled
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_alarmEnabled)
                    const Icon(
                      Icons.edit,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _alarmHour, minute: _alarmMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _alarmHour = picked.hour;
        _alarmMinute = picked.minute;
      });

      // Reschedule alarm with new time
      final success = await _alarmService.scheduleAlarm(
        _alarmHour,
        _alarmMinute,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder updated to ${_formatTime(_alarmHour, _alarmMinute)}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.bold(
          color: AppColors.textMuted,
          fontSize: 11.5,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Who is signed in — name and class, with the sign-in number underneath.
  Widget _buildProfileCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final name = (user?.name ?? '').trim();
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'Q';
        final meta = [user?.classNumber, user?.phone]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .map((value) => value.toString())
            .join('  ·  ');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppFonts.bold(
                    color: AppColors.onPrimary,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'QSPOT student' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.bold(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: AppFonts.regular(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.semiBold(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppFonts.regular(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/icons/Icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.book,
                        color: AppColors.primary,
                        size: 20,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingSmall),
              Text(
                'QSpot',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Your space for Quran videos and Islamic knowledge. Discover inspiring content from renowned speakers and scholars.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Row(
            children: [
              Text(
                'Version: ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              Text(
                _appVersion.isNotEmpty ? _appVersion : '…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showLogoutDialog(context, authProvider),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout, color: AppColors.danger),
                ),
                const SizedBox(width: AppTheme.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logout',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.user?.phone ?? 'Logged in',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger, size: 24),
            const SizedBox(width: AppTheme.paddingSmall),
            Text(
              'Logout',
              style: AppFonts.bold(color: AppColors.textPrimary, fontSize: 20),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppFonts.regular(color: AppColors.textMuted, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppFonts.medium(color: AppColors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Developed by',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchUrl('https://d4dx.co'),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/icons/D4DX _logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 20,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'D4DX Innovations LLP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Text(
          '© ${DateTime.now().year} D4DX Innovations LLP',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _navigateToContactUs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactUsScreen()),
    );
  }

  void _navigateToMyQuestions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyQuestionsScreen()),
    );
  }

  void _navigateToFaculties(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FacultiesScreen()),
    );
  }

  void _showAskQuestionDialog(BuildContext context) {
    // Delegate to the single shared Ask Question surface instead of a
    // duplicated form + POST implementation (GAP P4: "Ask Question
    // implemented three times").
    AskQuestionScreen.show(context);
  }

  Future<void> _sendFeedback(BuildContext context) async {
    debugPrint('Feedback button tapped');

    try {
      // Create the mailto URL with proper encoding
      const String email = 'mail@d4dx.co';
      const String subject = 'QSpot App Feedback';
      const String body =
          'Hi D4DX Team,\n\nI would like to share my feedback about the QSpot app:\n\n[Please write your feedback here]\n\nThank you!';

      final String encodedSubject = Uri.encodeComponent(subject);
      final String encodedBody = Uri.encodeComponent(body);

      final String mailtoUrl =
          'mailto:$email?subject=$encodedSubject&body=$encodedBody';
      final Uri emailUri = Uri.parse(mailtoUrl);

      debugPrint('Attempting to launch: $mailtoUrl');

      // Try multiple approaches to launch email
      bool launched = false;

      // Approach 1: Try with SENDTO action (more reliable on Android)
      try {
        final Uri sendtoUri = Uri(
          scheme: 'mailto',
          path: email,
          queryParameters: {'subject': subject, 'body': body},
        );

        launched = await launchUrl(
          sendtoUri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('SENDTO mailto launch result: $launched');
      } catch (e) {
        debugPrint('SENDTO mailto failed: $e');
      }

      // Approach 2: Try with simple mailto if first approach failed
      if (!launched) {
        try {
          final Uri simpleEmailUri = Uri.parse('mailto:$email');
          launched = await launchUrl(
            simpleEmailUri,
            mode: LaunchMode.externalApplication,
          );
          debugPrint('Simple mailto launch result: $launched');
        } catch (e) {
          debugPrint('Simple mailto failed: $e');
        }
      }

      // Approach 3: Try with platform-specific launch mode
      if (!launched) {
        try {
          launched = await launchUrl(
            emailUri,
            mode: LaunchMode.platformDefault,
          );
          debugPrint('Platform default launch result: $launched');
        } catch (e) {
          debugPrint('Platform default failed: $e');
        }
      }

      // Approach 4: Try with inAppWebView mode as last resort
      if (!launched) {
        try {
          launched = await launchUrl(emailUri, mode: LaunchMode.inAppWebView);
          debugPrint('InApp WebView launch result: $launched');
        } catch (e) {
          debugPrint('InApp WebView failed: $e');
        }
      }

      if (!launched) {
        throw Exception(
          'All email launch methods failed - no email client available',
        );
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      // Show a helpful dialog if there's an error
      if (context.mounted) {
        _showEmailFallbackDialog(context);
      }
    }
  }

  void _showEmailFallbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Icon(Icons.email, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Send Feedback',
                style: AppFonts.bold(color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No email app found. Please send your feedback manually to:',
                style: AppFonts.regular(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Email: ',
                          style: AppFonts.regular(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'mail@d4dx.co',
                            style: AppFonts.semiBold(color: AppColors.primary),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: 'mail@d4dx.co'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Email copied to clipboard',
                                  style: AppFonts.regular(
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                                backgroundColor: AppColors.primary,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          tooltip: 'Copy email',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subject: QSpot App Feedback',
                      style: AppFonts.regular(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: AppFonts.medium(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Copy the full email template
                const String fullTemplate = '''mail@d4dx.co

Subject: QSpot App Feedback

Hi D4DX Team,

I would like to share my feedback about the QSpot app:

[Please write your feedback here]

Thank you!''';

                Clipboard.setData(ClipboardData(text: fullTemplate));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Email template copied to clipboard',
                      style: AppFonts.regular(color: AppColors.onPrimary),
                    ),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Copy Template'),
            ),
          ],
        );
      },
    );
  }
}
