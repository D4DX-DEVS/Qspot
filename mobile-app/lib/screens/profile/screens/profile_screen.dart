import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../auth/model/user_model.dart';
import '../../auth/provider/auth_provider.dart';
import '../../../services/session.dart';
import '../../bookmark/screens/bookmarks_screen.dart';
import '../../question/screens/my_questions_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../services/course_service.dart';

/// The signed-in learner's identity and personal destinations.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Me'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text('Your learning space', style: AppTheme.sectionTitle),
          const SizedBox(height: 5),
          Text(
            'Keep your saved work, questions, and preferences close.',
            style: AppTheme.sectionIntro,
          ),
          const SizedBox(height: 18),
          _identity(context),
          const SizedBox(height: AppTheme.sectionGap),
          _shortcuts(context),
          const SizedBox(height: 24),
          _logout(context),
        ],
      ),
    );
  }

  Widget _identity(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final name = (user?.name ?? '').trim();
        final displayName = name.isNotEmpty ? name : 'Student';
        final phone = user?.phone ?? '';
        final classNumber = (user?.classNumber ?? '').trim();
        final language = user?.language ?? 'en';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(displayName),
                  style: AppFonts.bold(
                    color: AppColors.onPrimary,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.bold(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: AppFonts.regular(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (classNumber.isNotEmpty) _pill('Class $classNumber'),
                        _pill(language == 'ml' ? 'മലയാളം' : 'English'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editProfile(context, user),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Edit profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppFonts.bold(color: AppColors.primary, fontSize: 11.5),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, UserModel? user) async {
    final nameController = TextEditingController(text: user?.name ?? '');
    final classController = TextEditingController(
      text: user?.classNumber ?? '',
    );
    String language = user?.language ?? 'en';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            'Edit profile',
            style: AppFonts.medium(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: AppFonts.regular(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: classController,
                style: AppFonts.regular(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Class'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Language',
                    style: AppFonts.regular(color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  ToggleButtons(
                    isSelected: [language == 'en', language == 'ml'],
                    onPressed: (index) {
                      setDialogState(() => language = index == 0 ? 'en' : 'ml');
                    },
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('EN'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ML'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      // `PUT /api/user/me` is the single source of truth for language here —
      // `/api/user/prefs.language` is left alone to avoid double-writing the
      // same value through two endpoints (see report for the deviation note).
      //
      // AuthProvider (owned by the auth agent) has no setter to apply the
      // updated user back into its in-memory cache, so the new name/class/
      // language only take full effect after the next login — the identity
      // card below is refreshed by calling initialize() where possible.
      await ApiClient.put(
        '/api/user/me',
        body: {
          'name': nameController.text.trim(),
          'class': classController.text.trim(),
          'language': language,
        },
      );
      if (!context.mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _shortcuts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Your space',
            style: AppFonts.extraBold(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ),
        _shortcut(
          context,
          icon: Icons.school_outlined,
          label: 'My courses',
          subtitle: 'Choose the subjects you want to see',
          onTap: () => _editCourses(context),
        ),
        _shortcut(
          context,
          icon: Icons.help_outline,
          label: 'My Questions',
          subtitle: 'Questions you asked and their answers',
          builder: (_) => const MyQuestionsScreen(),
        ),
        _shortcut(
          context,
          icon: Icons.bookmark_border,
          label: 'Bookmarks',
          subtitle: 'Episodes you saved for later',
          builder: (_) => const BookmarksScreen(),
        ),
        _shortcut(
          context,
          icon: Icons.settings_outlined,
          label: 'Settings',
          subtitle: 'Notifications, reminders and more',
          builder: (_) => const SettingsScreen(),
        ),
      ],
    );
  }

  Widget _shortcut(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    WidgetBuilder? builder,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap:
              onTap ??
              () =>
                  Navigator.push(context, MaterialPageRoute(builder: builder!)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppFonts.semiBold(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.regular(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
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

  Future<void> _editCourses(BuildContext context) async {
    final courses = await CourseService.fetchActive(forSelection: true);
    if (!context.mounted) return;
    final auth = context.read<AuthProvider>();
    final selected = {...auth.user?.courseIds ?? const <String>[]};
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('My courses'),
          content: SizedBox(
            width: 360,
            child: courses.isEmpty
                ? const Text('No active courses are available yet.')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final course in courses)
                          CheckboxListTile(
                            value: selected.contains(course.id),
                            onChanged: (value) => setDialogState(() {
                              if (value == true) {
                                selected.add(course.id);
                              } else {
                                selected.remove(course.id);
                              }
                            }),
                            title: Text(course.title),
                            subtitle: course.subtitle.isEmpty
                                ? null
                                : Text(course.subtitle),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;

    try {
      final response = await ApiClient.put(
        '/api/user/me',
        body: {'courseIds': selected.toList()},
      );
      final userJson = response is Map && response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : null;
      if (userJson != null) {
        await auth.updateUser(UserModel.fromJson(userJson));
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Courses updated')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update courses: $e')));
    }
  }

  Widget _logout(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            onPressed: () => _confirmLogout(context, authProvider),
            icon: const Icon(Icons.logout, size: 18),
            label: Text('Logout', style: AppFonts.bold()),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          'Logout',
          style: AppFonts.medium(color: AppColors.textPrimary, fontSize: 19),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppFonts.regular(color: AppColors.textMuted, fontSize: 15),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await performLogout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => String.fromCharCode(part.runes.first).toUpperCase())
        .join();
    return parts.isEmpty ? '?' : parts;
  }
}
