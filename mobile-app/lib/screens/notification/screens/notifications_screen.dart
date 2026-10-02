import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../model/notification_model.dart';
import '../provider/notification_provider.dart';
import '../provider/notifications_screen_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../../widgets/common/surface_card.dart';
import '../../../widgets/common/soft_icon_tile.dart';
import '../../common/widgets/home_theme_scope.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NotificationsScreenProvider _screen = NotificationsScreenProvider();

  List<NotificationModel> get _filteredNotifications =>
      _screen.filteredNotifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _screen.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    await notificationProvider.loadNotifications();
    if (!mounted) return;
    _updateFilteredNotifications();
  }

  void _updateFilteredNotifications() {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    _screen.updateFiltered(notificationProvider, _searchController.text);
  }

  void _onSearchChanged(String query) {
    _updateFilteredNotifications();
  }

  @override
  Widget build(BuildContext context) {
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(
      child: ChangeNotifierProvider.value(
        value: _screen,
        child: Consumer<NotificationsScreenProvider>(
          builder: (context, screen, _) => _buildPage(context),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Notifications'),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const LoadingSkeleton();
          }

          if (notificationProvider.hasError) {
            return StateMessageView(
              icon: LucideIcons.circleAlert,
              title: 'Something Went Wrong',
              message: notificationProvider.errorMessage,
              onRetry: _loadNotifications,
            );
          }

          if (notificationProvider.notifications.isEmpty) {
            return const StateMessageView(
              icon: LucideIcons.bell,
              title: 'No Notifications',
              message: "You're all caught up! Check back later for updates.",
            );
          }

          return Column(
            children: [
              // Search bar
              StaggeredEntrance(child: _buildSearchBar(p)),

              // Notifications count
              StaggeredEntrance(index: 1, child: _buildNotificationsCount(p)),

              // Notifications list
              Expanded(
                child:
                    _filteredNotifications.isEmpty &&
                        _searchController.text.isNotEmpty
                    ? const StateMessageView(
                        icon: LucideIcons.searchX,
                        title: 'No Results Found',
                        message: 'Try searching with different keywords',
                      )
                    : _buildNotificationsList(p),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(HomePalette p) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        cursorColor: p.brand,
        style: AppFonts.regular(color: p.text),
        decoration: InputDecoration(
          hintText: 'Search Notifications...',
          hintStyle: AppFonts.regular(color: p.textMuted),
          prefixIcon: Icon(LucideIcons.search, color: p.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: p.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
            vertical: AppTheme.paddingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsCount(HomePalette p) {
    final count = _filteredNotifications.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      child: Row(
        children: [
          Text(
            '$count notification${count != 1 ? 's' : ''}',
            style: AppFonts.regular(color: p.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(HomePalette p) {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      backgroundColor: p.card,
      color: p.brand,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          return StaggeredEntrance(
            index: index + 2,
            child: _buildNotificationCard(p, notification),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(HomePalette p, NotificationModel notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: SurfaceCard(
        onTap: () => _onNotificationTap(p, notification),
        radius: 16,
        // Unread ones get a soft tint, a bolder title and a dot.
        color: notification.isRead ? null : p.brandSoft,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconTile(icon: LucideIcons.bell, tone: p.rose, size: 44),

            const SizedBox(width: AppTheme.paddingMedium),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: notification.isRead
                              ? AppFonts.semiBold(color: p.text, fontSize: 15)
                              : AppFonts.extraBold(color: p.text, fontSize: 15),
                        ),
                      ),
                      if (!notification.isRead)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 5),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.brand,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(width: 9, height: 9),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    notification.description,
                    style: AppFonts.regular(
                      color: p.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    notification.formattedDate,
                    style: AppFonts.regular(color: p.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNotificationTap(HomePalette p, NotificationModel notification) {
    // Mark read immediately so the unread badge (Home + this list) reflects
    // the tap right away (M21).
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).markAsRead(notification.id).then((_) {
      if (mounted) _updateFilteredNotifications();
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: AppFonts.bold(color: p.text, fontSize: 19),
              ),
              const SizedBox(height: 8),
              if (notification.formattedDate.isNotEmpty)
                Text(
                  notification.formattedDate,
                  style: AppFonts.regular(color: p.textMuted, fontSize: 12.5),
                ),
              const SizedBox(height: 16),
              Text(
                notification.description,
                style: AppFonts.regular(
                  color: p.text,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: PressableScale(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.brand,
                      foregroundColor: p.card,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
