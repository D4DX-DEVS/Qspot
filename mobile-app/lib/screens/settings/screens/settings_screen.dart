import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../../widgets/animation/pop_on_change.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../common/screens/contact_us_screen.dart';
import '../../question/screens/ask_question_screen.dart';
import '../../question/screens/my_questions_screen.dart';
import '../../speaker/screens/faculties_screen.dart';
import '../../schedule/service/alarm_service.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../services/session.dart';
import '../provider/settings_screen_provider.dart';
import '../widgets/settings_group_card.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section_title.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AlarmService _alarmService = AlarmService();
  final SettingsScreenProvider _s = SettingsScreenProvider();

  @override
  void initState() {
    super.initState();
    _s.loadAlarmSettings(_alarmService);
    _s.loadAppVersion();
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  // Same light/dark rule HomeThemeScope uses. Read from MediaQuery because
  // this State's context sits above the scope it creates.
  HomePalette get _p =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
      ? HomePalette.dark
      : HomePalette.light;

  @override
  Widget build(BuildContext context) {
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _s,
        child: Consumer<SettingsScreenProvider>(
          builder: (_, s, __) => _buildPage(s),
        ),
      ),
    );
  }

  Widget _buildPage(SettingsScreenProvider s) {
    return Scaffold(
      body: s.isLoading
          ? Center(child: CircularProgressIndicator(color: _p.brand))
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                SettingsHeader(
                  title: 'Settings',
                  subtitle: 'Manage your preferences and app details',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    AppTheme.paddingLarge +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildSections(context),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    return [
      const StaggeredEntrance(
        child: SettingsSectionTitle(
          icon: LucideIcons.bell,
          title: 'Notifications',
        ),
      ),
      StaggeredEntrance(child: _buildAlarmSettingsCard(context)),
      const SizedBox(height: AppTheme.paddingLarge),

      const StaggeredEntrance(
        index: 1,
        child: SettingsSectionTitle(
          icon: LucideIcons.settings,
          title: 'App Information',
        ),
      ),
      StaggeredEntrance(
        index: 1,
        child: SettingsGroupCard(
          children: [
            SettingsRow(
              icon: LucideIcons.info,
              tone: _p.rose,
              title: 'About Us',
              subtitle: 'Learn more about D4DX Innovations',
              onTap: () => _launchUrl('https://d4dx.co/about-us/'),
            ),
            SettingsRow(
              icon: LucideIcons.lifeBuoy,
              tone: _p.coral,
              title: 'Contact Us',
              subtitle: 'Get in touch with our team',
              onTap: () => _navigateToContactUs(context),
            ),
            SettingsRow(
              icon: LucideIcons.users,
              tone: _p.slate,
              title: 'Faculties',
              subtitle: 'Meet the scholars behind the episodes',
              onTap: () => _navigateToFaculties(context),
            ),
            SettingsRow(
              icon: LucideIcons.messageCircleQuestionMark,
              tone: _p.mint,
              title: 'Ask a Question',
              subtitle: 'Ask questions to our faculties',
              onTap: () => _showAskQuestionDialog(context),
            ),
            SettingsRow(
              icon: LucideIcons.history,
              tone: _p.teal,
              title: 'My Questions',
              subtitle: 'View your questions and answers',
              onTap: () => _navigateToMyQuestions(context),
            ),
            SettingsRow(
              icon: LucideIcons.messageSquareWarning,
              tone: _p.amber,
              title: 'Feedback',
              subtitle: 'Share your thoughts and suggestions',
              onTap: () => _sendFeedback(context),
            ),
            SettingsRow(
              icon: LucideIcons.shield,
              tone: _p.slate,
              title: 'Privacy Policy',
              subtitle: 'View our privacy and data policy',
              onTap: () => _launchUrl('https://d4dx.co/privacy-policy/'),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTheme.paddingLarge),

      const StaggeredEntrance(
        index: 2,
        child: SettingsSectionTitle(
          icon: LucideIcons.smartphone,
          title: 'App Details',
        ),
      ),
      StaggeredEntrance(index: 2, child: _buildInfoCard(context)),
      const SizedBox(height: AppTheme.paddingLarge),

      StaggeredEntrance(index: 3, child: _buildLogoutButton(context)),
      const SizedBox(height: AppTheme.paddingLarge),

      StaggeredEntrance(index: 4, child: _buildFooter(context)),
    ];
  }

  Widget _buildAlarmSettingsCard(BuildContext context) {
    return SettingsGroupCard(
      children: [
        SettingsRow(
          icon: LucideIcons.bell,
          tone: _p.rose,
          title: 'Daily Reminder',
          subtitle: _s.alarmEnabled
              ? 'On · get notified to watch videos'
              : 'Off · switch on to get a daily reminder',
          trailing: PopOnChange(
            active: _s.alarmEnabled,
            peak: 1.15,
            child: Switch(
              value: _s.alarmEnabled,
              onChanged: (value) async {
                if (value) {
                  // Request permissions first
                  final hasPermission = await _alarmService
                      .requestPermissions();
                  if (!hasPermission) {
                    if (context.mounted) {
                      AppSnackBar.show(
                        context,
                        message:
                            'Please allow notifications in your phone settings to get daily reminders.',
                        color: AppColors.warningOrange,
                        duration: const Duration(seconds: 4),
                      );
                    }
                    return;
                  }

                  // Schedule alarm
                  final success = await _alarmService.scheduleAlarm(
                    _s.alarmHour,
                    _s.alarmMinute,
                  );

                  if (success && context.mounted) {
                    _s.setAlarmEnabled(true);
                    AppSnackBar.show(
                      context,
                      message:
                          'Daily reminder set for ${_formatTime(_s.alarmHour, _s.alarmMinute)}',
                      color: AppColors.success,
                    );
                  }
                } else {
                  // Cancel alarm
                  await _alarmService.cancelAlarm();
                  _s.setAlarmEnabled(false);
                  if (context.mounted) {
                    AppSnackBar.show(
                      context,
                      message: 'Daily reminder turned off',
                      color: AppColors.success,
                    );
                  }
                }
              },
              // Clear on/off states: filled brand track when on, outlined
              // grey when off.
              activeThumbColor: AppColors.white,
              activeTrackColor: _p.brand,
              inactiveThumbColor: _p.textMuted,
              inactiveTrackColor: _p.background,
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.transparent
                    : _p.textMuted,
              ),
            ),
          ),
        ),
        // The time only matters while the reminder is on.
        if (_s.alarmEnabled)
          StaggeredEntrance(
            rise: 8,
            child: SettingsRow(
              icon: LucideIcons.clock,
              tone: _p.rose,
              title: 'Reminder Time',
              subtitle: _formatTime(_s.alarmHour, _s.alarmMinute),
              subtitleStyle: AppFonts.bold(color: _p.brand, fontSize: 16),
              onTap: () => _showTimePicker(context),
            ),
          ),
      ],
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _s.alarmHour, minute: _s.alarmMinute),
    );

    if (picked != null) {
      _s.setAlarmTime(picked.hour, picked.minute);

      // Reschedule alarm with new time
      final success = await _alarmService.scheduleAlarm(
        _s.alarmHour,
        _s.alarmMinute,
      );

      if (success && context.mounted) {
        AppSnackBar.show(
          context,
          message:
              'Daily reminder moved to ${_formatTime(_s.alarmHour, _s.alarmMinute)}',
          color: AppColors.success,
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

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: _p.cardBorder, width: 1),
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
                      return Icon(LucideIcons.book, color: _p.brand, size: 20);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingSmall),
              Text(
                'QSpot',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _p.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Your space for Quran videos and Islamic knowledge. Discover inspiring content from renowned speakers and scholars.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _p.textMuted, height: 1.5),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Row(
            children: [
              Text(
                'Version: ',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _p.textMuted),
              ),
              Text(
                _s.appVersion.isNotEmpty ? _s.appVersion : '…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _p.brand,
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
        return PressableScale(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            decoration: BoxDecoration(
              color: _p.error.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: _p.error.withValues(alpha: 0.3),
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
                      color: _p.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.logOut, color: _p.error),
                  ),
                  const SizedBox(width: AppTheme.paddingMedium),
                  Expanded(
                    child: Text(
                      'Logout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _p.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: _p.error),
                ],
              ),
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
        backgroundColor: _p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.logOut, color: _p.error, size: 24),
            const SizedBox(width: AppTheme.paddingSmall),
            Text('Logout', style: AppFonts.bold(color: _p.text, fontSize: 20)),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppFonts.regular(color: _p.textMuted, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: AppFonts.medium(color: _p.text)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _p.error,
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
          ).textTheme.bodySmall?.copyWith(color: _p.textMuted),
        ),
        const SizedBox(height: 4),
        PressableScale(
          child: GestureDetector(
            onTap: () => _launchUrl('https://d4dx.co'),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                color: _p.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/icons/D4DX _logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      width: 100,
                      height: 100,
                      child: Icon(
                        LucideIcons.building2,
                        color: _p.brand,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Text(
          '© ${DateTime.now().year} D4DX Innovations LLP',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _p.textMuted),
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
          backgroundColor: _p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Icon(LucideIcons.mail, color: _p.brand, size: 24),
              const SizedBox(width: 8),
              Text('Send Feedback', style: AppFonts.bold(color: _p.text)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No email app found. Please send your feedback manually to:',
                style: AppFonts.regular(color: _p.text),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _p.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _p.cardBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Email: ',
                          style: AppFonts.regular(
                            color: _p.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'mail@d4dx.co',
                            style: AppFonts.semiBold(color: _p.brand),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: 'mail@d4dx.co'),
                            );
                            AppSnackBar.show(
                              context,
                              message: 'Email address copied',
                              color: AppColors.success,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          icon: Icon(
                            LucideIcons.copy,
                            color: _p.brand,
                            size: 18,
                          ),
                          tooltip: 'Copy Email',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subject: QSpot App Feedback',
                      style: AppFonts.regular(
                        color: _p.textMuted,
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
              child: Text('Close', style: AppFonts.medium(color: _p.brand)),
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
                AppSnackBar.show(
                  context,
                  message: 'Email copied. Paste it into your mail app to send.',
                  color: AppColors.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _p.brand,
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
