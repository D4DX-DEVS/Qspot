import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/nav_list_card.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/soft_outline_button.dart';
import '../widgets/profile_identity_card.dart';
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
      appBar: const CommonAppBar(title: 'Me'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _identity(context),
          const SizedBox(height: 22),
          _shortcuts(context),
          const SizedBox(height: 22),
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

        return ProfileIdentityCard(
          name: displayName,
          phone: phone,
          tags: [
            if (classNumber.isNotEmpty) 'Class $classNumber',
            language == 'ml' ? 'മലയാളം' : 'English',
          ],
          onEdit: () => _editProfile(context, user),
        );
      },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            'Edit profile',
            style: AppFonts.medium(
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: AppFonts.regular(
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: classController,
                style: AppFonts.regular(
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(labelText: 'Class'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Language',
                    style: AppFonts.regular(
                      color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                    ),
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
      AppSnackBar.show(
        context,
        message: 'Your profile has been updated',
        color: AppColors.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: e is ApiException
            ? e.message
            : 'We couldn\'t update your profile. Please try again.',
        color: AppColors.danger,
      );
    }
  }

  Widget _shortcuts(BuildContext context) {
    final tone = HomePalette.of(context).rose;
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    final items = [
      NavListCard(
        icon: Icons.school_outlined,
        tone: tone,
        circleIcon: true,
        subtitleLines: 2,
        title: 'My courses',
        subtitle: 'Choose the subjects you want to see',
        onTap: () => _editCourses(context),
      ),
      NavListCard(
        icon: Icons.help_outline,
        tone: tone,
        circleIcon: true,
        subtitleLines: 2,
        title: 'My Questions',
        subtitle: 'Questions you asked and their answers',
        onTap: () => open(const MyQuestionsScreen()),
      ),
      NavListCard(
        icon: Icons.bookmark_border,
        tone: tone,
        circleIcon: true,
        subtitleLines: 2,
        title: 'Bookmarks',
        subtitle: 'Episodes you saved for later',
        onTap: () => open(const BookmarksScreen()),
      ),
      NavListCard(
        icon: Icons.settings_outlined,
        tone: tone,
        circleIcon: true,
        subtitleLines: 2,
        title: 'Settings',
        subtitle: 'Notifications, reminders and more',
        onTap: () => open(const SettingsScreen()),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Your learning space',
          subtitle: 'Keep your saved work, questions, and preferences close.',
        ),
        const SizedBox(height: 14),
        for (final item in items)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: item),
      ],
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
                            activeColor: Theme.of(
                              dialogContext,
                            ).colorScheme.primary,
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
      AppSnackBar.show(
        context,
        message: 'Your courses have been updated',
        color: AppColors.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: e is ApiException
            ? e.message
            : 'We couldn\'t update your courses. Please try again.',
        color: AppColors.danger,
      );
    }
  }

  Widget _logout(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SoftOutlineButton(
          label: 'Logout',
          icon: Icons.logout_rounded,
          expand: true,
          onPressed: () => _confirmLogout(context, authProvider),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          'Logout',
          style: AppFonts.medium(
            color: Theme.of(dialogContext).colorScheme.onSurface,
            fontSize: 19,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppFonts.regular(
            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppFonts.medium(
                color: Theme.of(dialogContext).colorScheme.onSurface,
              ),
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
}
