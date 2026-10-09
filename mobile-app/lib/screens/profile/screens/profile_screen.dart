import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../services/api_client.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pop_on_change.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/initials_avatar.dart';
import '../../../widgets/common/home_sheet_shell.dart';
import '../../../widgets/common/nav_list_card.dart';
import '../../../widgets/common/section_header.dart';
import '../widgets/profile_identity_card.dart';
import '../../auth/model/user_model.dart';
import '../../auth/provider/auth_provider.dart';
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
      appBar: const CommonAppBar(title: 'Me', isDrawerNeeded: true),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          StaggeredEntrance(child: _identity(context)),
          const SizedBox(height: 22),
          _shortcuts(context),
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
          imageUrl: user?.profileImageUrl,
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
    final formKey = GlobalKey<FormState>();
    String language = user?.language ?? 'en';
    final picker = ImagePicker();
    XFile? selectedPhoto;
    Uint8List? selectedPhotoBytes;
    var removePhoto = false;
    String? photoError;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => HomeSheetShell(
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final palette = HomePalette.of(sheetContext);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Edit Profile',
                                style: AppFonts.bold(
                                  color: palette.text,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () =>
                                  Navigator.pop(sheetContext, false),
                              icon: const Icon(LucideIcons.x),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InitialsAvatar(
                                  name: (user?.name ?? '').trim().isEmpty
                                      ? 'Student'
                                      : user!.name!,
                                  size: 84,
                                  gradient: HomePalette.of(
                                    sheetContext,
                                  ).heroGradient,
                                  imageProvider: selectedPhotoBytes != null
                                      ? MemoryImage(selectedPhotoBytes!)
                                      : (removePhoto ||
                                                user?.profileImageUrl == null
                                            ? null
                                            : NetworkImage(
                                                user!.profileImageUrl!,
                                              )),
                                  ringWidth: 2.5,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        try {
                                          final picked = await picker.pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 85,
                                            maxWidth: 1000,
                                            maxHeight: 1000,
                                          );
                                          if (picked == null) return;
                                          final bytes = await picked
                                              .readAsBytes();
                                          if (!sheetContext.mounted) return;
                                          setSheetState(() {
                                            selectedPhoto = picked;
                                            selectedPhotoBytes = bytes;
                                            removePhoto = false;
                                            photoError = null;
                                          });
                                        } catch (_) {
                                          if (!sheetContext.mounted) return;
                                          setSheetState(() {
                                            photoError =
                                                'Could not choose that photo.';
                                          });
                                        }
                                      },
                                      icon: const Icon(
                                        LucideIcons.imagePlus,
                                        size: 17,
                                      ),
                                      label: Text(
                                        selectedPhoto == null
                                            ? 'Choose photo'
                                            : 'Change photo',
                                      ),
                                    ),
                                    if (selectedPhotoBytes != null ||
                                        (!removePhoto &&
                                            user?.profileImageUrl != null))
                                      TextButton(
                                        onPressed: () => setSheetState(() {
                                          selectedPhoto = null;
                                          selectedPhotoBytes = null;
                                          removePhoto = true;
                                          photoError = null;
                                        }),
                                        child: const Text('Remove'),
                                      ),
                                  ],
                                ),
                                if (photoError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      photoError!,
                                      style: AppFonts.regular(
                                        color: Theme.of(
                                          sheetContext,
                                        ).colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                TextFormField(
                                  controller: nameController,
                                  style: AppFonts.regular(
                                    color: Theme.of(
                                      sheetContext,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    final name = value?.trim() ?? '';
                                    if (name.isEmpty) return 'Name is required';
                                    if (name.length < 3) {
                                      return 'Name must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  controller: classController,
                                  style: AppFonts.regular(
                                    color: Theme.of(
                                      sheetContext,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Class',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    final classNumber = int.tryParse(
                                      value?.trim() ?? '',
                                    );
                                    if (classNumber == null) {
                                      return 'Class is required';
                                    }
                                    if (classNumber < 1 || classNumber > 12) {
                                      return 'Enter a class from 1 to 12';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'Language',
                                      style: AppFonts.regular(
                                        color: Theme.of(
                                          sheetContext,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const Spacer(),
                                    ToggleButtons(
                                      isSelected: [
                                        language == 'en',
                                        language == 'ml',
                                      ],
                                      onPressed: (index) {
                                        setSheetState(
                                          () => language = index == 0
                                              ? 'en'
                                              : 'ml',
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      children: [
                                        PopOnChange(
                                          active: language == 'en',
                                          peak: 1.15,
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text('EN'),
                                          ),
                                        ),
                                        PopOnChange(
                                          active: language == 'ml',
                                          peak: 1.15,
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text('ML'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.pop(sheetContext, false),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: palette.brand,
                                  foregroundColor: palette.card,
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  if (formKey.currentState?.validate() !=
                                      true) {
                                    return;
                                  }
                                  Navigator.pop(sheetContext, true);
                                },
                                child: const Text('Save profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      final fields = <String, String>{
        'name': nameController.text.trim(),
        'class': classController.text.trim(),
        'language': language,
        if (removePhoto) 'removeProfileImage': 'true',
      };
      dynamic response;
      if (selectedPhoto != null) {
        final bytes = selectedPhotoBytes ?? await selectedPhoto!.readAsBytes();
        response = await ApiClient.multipart(
          '/api/user/me',
          method: 'PUT',
          fields: fields,
          files: [
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: _photoFileName(selectedPhoto!.name),
              contentType: MediaType.parse(_photoMimeType(selectedPhoto!.name)),
            ),
          ],
        );
      } else {
        response = await ApiClient.put('/api/user/me', body: fields);
      }
      if (!context.mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userJson = response is Map && response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : null;
      if (userJson != null) {
        await authProvider.updateUser(UserModel.fromJson(userJson));
      } else {
        await authProvider.initialize();
      }
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

  String _photoMimeType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  String _photoFileName(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    final safeExtension =
        const {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(extension)
        ? extension
        : 'jpg';
    return 'profile.$safeExtension';
  }

  Widget _shortcuts(BuildContext context) {
    final tone = HomePalette.of(context).rose;
    void open(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    final items = [
      NavListCard(
        icon: LucideIcons.graduationCap,
        tone: tone,
        circleIcon: true,
        title: 'My Courses',
        subtitle: 'Choose the subjects you want to see',
        onTap: () => _editCourses(context),
      ),
      NavListCard(
        icon: LucideIcons.circleQuestionMark,
        tone: tone,
        circleIcon: true,
        title: 'My Questions',
        subtitle: 'Questions you asked and their answers',
        onTap: () => open(const MyQuestionsScreen()),
      ),
      NavListCard(
        icon: LucideIcons.bookmark,
        tone: tone,
        circleIcon: true,
        title: 'Bookmarks',
        subtitle: 'Episodes you saved for later',
        onTap: () => open(const BookmarksScreen()),
      ),
      NavListCard(
        icon: LucideIcons.settings,
        tone: tone,
        circleIcon: true,
        title: 'Settings',
        subtitle: 'Notifications, reminders and more',
        onTap: () => open(const SettingsScreen()),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StaggeredEntrance(
          index: 1,
          child: SectionHeader(
            title: 'Your Learning Space',
            subtitle: 'Keep your saved work, questions, and preferences close.',
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StaggeredEntrance(index: i + 2, child: items[i]),
          ),
      ],
    );
  }

  Future<void> _editCourses(BuildContext context) async {
    final courses = await CourseService.fetchActive(forSelection: true);
    if (!context.mounted) return;
    final auth = context.read<AuthProvider>();
    final selected = {...auth.user?.courseIds ?? const <String>[]};
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => HomeSheetShell(
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final palette = HomePalette.of(sheetContext);
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'My Courses',
                              style: AppFonts.bold(
                                color: palette.text,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(sheetContext, false),
                            icon: const Icon(LucideIcons.x),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose the subjects you want to see.',
                              style: AppFonts.regular(
                                color: palette.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (courses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'No active courses are available yet.',
                                ),
                              ),
                            for (final course in courses)
                              CheckboxListTile(
                                value: selected.contains(course.id),
                                onChanged: (value) => setSheetState(() {
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
                                activeColor: palette.brand,
                                contentPadding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.brand,
                                foregroundColor: palette.card,
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: courses.isEmpty
                                  ? null
                                  : () => Navigator.pop(sheetContext, true),
                              child: const Text('Save courses'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
}
