import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/schedule_provider.dart';
import '../model/schedule_model.dart';
import '../../../themes/app_theme.dart';
import '../service/alarm_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final scheduleProvider = Provider.of<ScheduleProvider>(
      context,
      listen: false,
    );
    await scheduleProvider.initialize();
  }

  Future<void> _onRefresh() async {
    final scheduleProvider = Provider.of<ScheduleProvider>(
      context,
      listen: false,
    );
    await scheduleProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProvider, child) {
          if (scheduleProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.gradientEnd),
            );
          }

          if (scheduleProvider.hasError) {
            return _buildErrorState(
              scheduleProvider.errorMessage,
              () => _onRefresh(),
            );
          }

          if (scheduleProvider.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            backgroundColor: AppTheme.surface,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Schedules
                  if (scheduleProvider.upcomingSchedules.isNotEmpty) ...[
                    _buildSectionHeader('Upcoming Classes'),
                    const SizedBox(height: AppTheme.paddingSmall),
                    ...scheduleProvider.upcomingSchedules.map((schedule) {
                      return _buildScheduleCard(schedule, isUpcoming: true);
                    }),
                  ],

                  // Completed Schedules
                  if (scheduleProvider.completedSchedules.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.paddingLarge),
                    _buildSectionHeader('Completed Classes'),
                    const SizedBox(height: AppTheme.paddingSmall),
                    ...scheduleProvider.completedSchedules.map((schedule) {
                      return _buildScheduleCard(schedule, isUpcoming: false);
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildScheduleCard(
    ScheduleModel schedule, {
    required bool isUpcoming,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isUpcoming
              ? AppTheme.primary.withValues(alpha: 0.25)
              : AppTheme.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () => _showScheduleDetails(schedule),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Row(
              children: [
                // Date badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: isUpcoming ? AppTheme.primaryGradient : null,
                    color: isUpcoming ? null : AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        schedule.date.day.toString(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: isUpcoming
                                  ? AppTheme.onPrimary
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        schedule.formattedDate.split(' ')[0],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isUpcoming
                              ? AppTheme.onPrimary
                              : AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.paddingMedium),

                // Schedule info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class number
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? AppTheme.primarySoft
                              : AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          schedule.classNumber,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isUpcoming
                                    ? AppTheme.gradientEnd
                                    : AppTheme.secondaryGray,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        schedule.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Time and faculty
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.secondaryGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.formattedTime,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.secondaryGray,
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(width: 12),
                          if (schedule.facultyName != null &&
                              schedule.facultyName!.isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: AppTheme.secondaryGray,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      schedule.facultyName!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.secondaryGray,
                                            fontSize: 12,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status icon or reminder button
                if (isUpcoming)
                  IconButton(
                    icon: const Icon(Icons.notifications_active),
                    color: AppTheme.gradientEnd,
                    onPressed: () => _setReminder(schedule),
                    tooltip: 'Set Reminder',
                  )
                else
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryGray,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.secondaryGray),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Failed to Load Schedule',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
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
              onPressed: onRetry,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: AppTheme.secondaryGray),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'No Schedule Available',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Check back later for upcoming classes',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryGray),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDetails(ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            schedule.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.class_, schedule.classNumber),
              _buildDetailRow(Icons.calendar_today, schedule.formattedDate),
              _buildDetailRow(Icons.access_time, schedule.formattedTime),
              if (schedule.facultyName != null &&
                  schedule.facultyName!.isNotEmpty)
                _buildDetailRow(Icons.person, schedule.facultyName!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.gradientEnd),
              ),
            ),
            if (schedule.isUpcoming)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _setReminder(schedule);
                },
                icon: const Icon(Icons.notifications_active, size: 18),
                label: const Text('Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gradientStart,
                  foregroundColor: AppTheme.onPrimary,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.gradientEnd),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setReminder(ScheduleModel schedule) async {
    try {
      final alarmService = AlarmService();
      // We'll use a dummy video ID based on schedule ID for the reminder
      final success = await alarmService.scheduleVideoReminder(
        'schedule_${schedule.id}', // Use string-based ID to avoid conflicts
        '${schedule.classNumber}: ${schedule.title}',
        schedule.date,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${schedule.relativeTime}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set reminder: ${e.toString()}'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    }
  }
}
