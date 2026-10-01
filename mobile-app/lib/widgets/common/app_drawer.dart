import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/auth/provider/auth_provider.dart';
import '../../screens/bookmark/screens/bookmarks_screen.dart';
import '../../screens/common/screens/contact_us_screen.dart';
import '../../screens/common/widgets/home_theme_scope.dart';
import '../../screens/notification/screens/notifications_screen.dart';
import '../../screens/schedule/screens/schedule_screen.dart';
import '../../screens/settings/screens/settings_screen.dart';
import '../../services/session.dart';
import '../../utils/feedback_mail.dart';
import '../../themes/home_palette.dart';
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
                return AppDrawerHeader(
                  name: name.isEmpty ? 'Welcome' : name,
                  subtitle: classNumber.isNotEmpty
                      ? 'Class $classNumber'
                      : (user?.phone ?? ''),
                  onClose: () => Navigator.pop(context),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const AppDrawerSectionLabel('General'),
                  AppDrawerTile(
                    icon: Icons.bookmark_border,
                    label: 'Bookmarks',
                    onTap: () => _open(context, const BookmarksScreen()),
                  ),
                  AppDrawerTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Schedule',
                    onTap: () => _open(context, const ScheduleScreen()),
                  ),
                  AppDrawerTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () => _open(context, const NotificationsScreen()),
                  ),
                  const AppDrawerSectionLabel('Support'),
                  AppDrawerTile(
                    icon: Icons.support_agent_outlined,
                    label: 'Contact us',
                    onTap: () => _open(context, const ContactUsScreen()),
                  ),
                  AppDrawerTile(
                    icon: Icons.feedback_outlined,
                    label: 'Feedback',
                    onTap: () => _sendFeedback(context),
                  ),
                  const AppDrawerSectionLabel('Account'),
                  AppDrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => _open(context, const SettingsScreen()),
                  ),
                  AppDrawerTile(
                    icon: Icons.logout,
                    label: 'Logout',
                    isDestructive: true,
                    onTap: () => _logout(context),
                  ),
                  const SafeArea(top: false, child: AppDrawerFooter()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
