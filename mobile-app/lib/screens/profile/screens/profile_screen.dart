import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_theme.dart';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          'Me',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text('Your learning space', style: AppTheme.sectionTitle),
          const SizedBox(height: 5),
          const Text(
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
            color: AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(displayName),
                  style: const TextStyle(
                    color: AppTheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
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
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
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
                  color: AppTheme.primary,
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
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
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
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: const Text(
            'Edit profile',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: classController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Class'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Language',
                    style: TextStyle(color: AppTheme.textMuted),
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
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Widget _shortcuts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Your space',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
        color: AppTheme.background,
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
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 19, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textMuted,
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
          backgroundColor: AppTheme.background,
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
                            activeColor: AppTheme.primary,
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
              foregroundColor: AppTheme.danger,
              side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            onPressed: () => _confirmLogout(context, authProvider),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 19),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: AppTheme.onPrimary,
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
