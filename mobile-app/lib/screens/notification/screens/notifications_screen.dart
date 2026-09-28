import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/notification_model.dart';
import '../provider/notification_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/loading_skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<NotificationModel> _filteredNotifications = [];

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
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    await notificationProvider.loadNotifications();
    _updateFilteredNotifications();
  }

  void _updateFilteredNotifications() {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredNotifications =
            notificationProvider.notificationsWithReadStatus;
      } else {
        _filteredNotifications = notificationProvider.searchNotifications(
          _searchController.text,
        );
      }
    });
  }

  void _onSearchChanged(String query) {
    _updateFilteredNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CommonAppBar(title: 'Notifications'),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const LoadingSkeleton();
          }

          if (notificationProvider.hasError) {
            return _buildErrorState(notificationProvider.errorMessage);
          }

          if (notificationProvider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Search bar
              _buildSearchBar(),

              // Notifications count
              _buildNotificationsCount(),

              // Notifications list
              Expanded(
                child:
                    _filteredNotifications.isEmpty &&
                        _searchController.text.isNotEmpty
                    ? _buildNoSearchResults()
                    : _buildNotificationsList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppFonts.regular(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search notifications...',
          hintStyle: AppFonts.regular(color: AppTheme.secondaryGray),
          prefixIcon: Icon(Icons.search, color: AppTheme.secondaryGray),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.secondaryGray),
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

  Widget _buildNotificationsCount() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      child: Row(
        children: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Text(
                '${_filteredNotifications.length} notification${_filteredNotifications.length != 1 ? 's' : ''}',
                style: AppFonts.regular(
                  color: AppTheme.secondaryGray,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      backgroundColor: AppTheme.surface,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: AppTheme.paddingMedium),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppFonts.medium(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppTheme.paddingSmall),

                    Text(
                      notification.description,
                      style: AppFonts.regular(
                        color: AppTheme.secondaryGray,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppTheme.paddingSmall),

                    Text(
                      notification.formattedDate,
                      style: AppFonts.regular(
                        color: AppTheme.secondaryGray,
                        fontSize: 12,
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppTheme.secondaryGray,
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Notifications',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'You\'re all caught up! Check back later for updates.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.secondaryGray),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Results Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Try searching with different keywords',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryGray),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gradientStart,
                foregroundColor: AppTheme.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    // Mark read immediately so the unread badge (Home + this list) reflects
    // the tap right away (M21).
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).markAsRead(notification.id);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
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
                style: AppFonts.bold(color: AppTheme.textPrimary, fontSize: 19),
              ),
              const SizedBox(height: 8),
              if (notification.formattedDate.isNotEmpty)
                Text(
                  notification.formattedDate,
                  style: AppFonts.regular(
                    color: AppTheme.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                notification.description,
                style: AppFonts.regular(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
