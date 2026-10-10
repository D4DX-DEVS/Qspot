import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../screens/auth/provider/auth_provider.dart';
import '../../screens/bookmark/screens/bookmarks_screen.dart';
import '../../screens/common/screens/contact_us_screen.dart';
import '../../screens/common/widgets/home_theme_scope.dart';
import '../../screens/notification/screens/notifications_screen.dart';
import '../../screens/question/screens/my_questions_screen.dart';
import '../../screens/schedule/screens/schedule_screen.dart';
import '../../screens/settings/screens/settings_screen.dart';
import '../../services/session.dart';
import '../../utils/feedback_mail.dart';
import '../../themes/home_palette.dart';
import '../animation/staggered_entrance.dart';
import 'app_drawer_footer.dart';
import 'app_drawer_header.dart';
import 'app_drawer_section_label.dart';
import 'app_drawer_tile.dart';
import 'frosted_panel.dart';
import 'logout_confirm_dialog.dart';

/// Slides the [AppDrawer] in from the left over the current screen.
///
/// Built as a route (not a Scaffold drawer) so any screen can open it from
/// [CommonAppBar] without wiring a `drawer:` into its own Scaffold. The
/// route gets the burgundy home theme, following the phone's light/dark mode.
Future<void> showAppDrawer(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => HomeThemeScope(
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: (width * 0.78).clamp(240.0, 320.0),
          child: AppDrawer(screenContext: context),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

/// Side menu with the extra pages and Logout. [screenContext] is the screen
/// that opened it: navigation and logout run against that context, since the
/// drawer's own route is closed first.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.screenContext});

  final BuildContext screenContext;

  void _open(BuildContext drawerContext, Widget screen) {
    Navigator.pop(drawerContext);
    Navigator.push(screenContext, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _sendFeedback(BuildContext drawerContext) async {
    Navigator.pop(drawerContext);
    if (!screenContext.mounted) return;
    await sendFeedbackMail(screenContext);
  }

  Future<void> _logout(BuildContext drawerContext) async {
    Navigator.pop(drawerContext);
    if (!screenContext.mounted) return;
    final confirmed = await showLogoutConfirmDialog(screenContext);
    if (confirmed && screenContext.mounted) {
      await performLogout(screenContext);
    }
  }

  /// Rows glide in one after another when the drawer opens.
  Widget _entrance(int index, Widget child) => StaggeredEntrance(
    index: index,
    maxStaggered: 13,
    step: const Duration(milliseconds: 35),
    rise: 12,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return FrostedPanel(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
      color: HomePalette.of(context).background,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AuthProvider>(
              builder: (_, auth, _) {
                final user = auth.user;
                final name = (user?.name ?? '').trim();
                final classNumber = (user?.classNumber ?? '').trim();
                return _entrance(
                  0,
                  AppDrawerHeader(
                    name: name.isEmpty ? 'Welcome' : name,
                    imageUrl: user?.profileImageUrl,
                    subtitle: classNumber.isNotEmpty
                        ? 'Class $classNumber'
                        : (user?.phone ?? ''),
                    onClose: () => Navigator.pop(context),
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _entrance(1, const AppDrawerSectionLabel('General')),
                  _entrance(
                    2,
                    AppDrawerTile(
                      icon: LucideIcons.bookmark,
                      label: 'Saved',
                      onTap: () => _open(context, const BookmarksScreen()),
                    ),
                  ),
                  _entrance(
                    3,
                    AppDrawerTile(
                      icon: LucideIcons.messageSquareText,
                      label: 'My Questions',
                      onTap: () => _open(context, const MyQuestionsScreen()),
                    ),
                  ),
                  _entrance(
                    4,
                    AppDrawerTile(
                      icon: LucideIcons.calendar,
                      label: 'Schedule',
                      onTap: () => _open(context, const ScheduleScreen()),
                    ),
                  ),
                  _entrance(
                    5,
                    AppDrawerTile(
                      icon: LucideIcons.bell,
                      label: 'Notifications',
                      onTap: () => _open(context, const NotificationsScreen()),
                    ),
                  ),
                  _entrance(6, const AppDrawerSectionLabel('Support')),
                  _entrance(
                    7,
                    AppDrawerTile(
                      icon: LucideIcons.headset,
                      label: 'Contact Us',
                      onTap: () => _open(context, const ContactUsScreen()),
                    ),
                  ),
                  _entrance(
                    8,
                    AppDrawerTile(
                      icon: LucideIcons.messageSquareWarning,
                      label: 'Feedback',
                      onTap: () => _sendFeedback(context),
                    ),
                  ),
                  _entrance(9, const AppDrawerSectionLabel('Account')),
                  _entrance(
                    10,
                    AppDrawerTile(
                      icon: LucideIcons.settings,
                      label: 'Settings',
                      onTap: () => _open(context, const SettingsScreen()),
                    ),
                  ),
                  _entrance(
                    11,
                    AppDrawerTile(
                      icon: LucideIcons.logOut,
                      label: 'Logout',
                      isDestructive: true,
                      onTap: () => _logout(context),
                    ),
                  ),
                  _entrance(
                    12,
                    const SafeArea(top: false, child: AppDrawerFooter()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
