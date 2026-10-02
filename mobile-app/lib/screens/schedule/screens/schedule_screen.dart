import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../provider/schedule_provider.dart';
import '../model/schedule_model.dart';
import '../../../themes/app_colors.dart';
import '../../../widgets/common/app_snack_bar.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';
import '../../../themes/home_palette.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/animation/staggered_entrance.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/common/state_message_view.dart';
import '../../../widgets/common/surface_card.dart';
import '../../common/widgets/home_theme_scope.dart';
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
    // Burgundy home theme; the page reads colours from the context inside it.
    return HomeThemeScope(child: Builder(builder: _buildPage));
  }

  Widget _buildPage(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Schedule'),
      body: Consumer<ScheduleProvider>(
        builder: (context, scheduleProvider, child) {
          if (scheduleProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: p.brand));
          }

          if (scheduleProvider.hasError) {
            return StateMessageView(
              icon: LucideIcons.circleAlert,
              title: 'Failed to Load Schedule',
              message: scheduleProvider.errorMessage,
              onRetry: _onRefresh,
            );
          }

          if (scheduleProvider.isEmpty) {
            return const StateMessageView(
              icon: LucideIcons.calendar,
              title: 'No Schedule Available',
              message: 'Check back later for upcoming classes',
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            backgroundColor: p.card,
            color: p.brand,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Schedules
                  if (scheduleProvider.upcomingSchedules.isNotEmpty) ...[
                    StaggeredEntrance(
                      child: _buildSectionHeader(p, 'Upcoming Classes'),
                    ),
                    ...scheduleProvider.upcomingSchedules.indexed.map((entry) {
                      return StaggeredEntrance(
                        index: entry.$1 + 1,
                        child: _buildScheduleCard(
                          p,
                          entry.$2,
                          isUpcoming: true,
                        ),
                      );
                    }),
                  ],

                  // Completed Schedules
                  if (scheduleProvider.completedSchedules.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.paddingMedium),
                    StaggeredEntrance(
                      child: _buildSectionHeader(p, 'Completed Classes'),
                    ),
                    ...scheduleProvider.completedSchedules.indexed.map((entry) {
                      return StaggeredEntrance(
                        index: entry.$1 + 1,
                        child: _buildScheduleCard(
                          p,
                          entry.$2,
                          isUpcoming: false,
                        ),
                      );
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

  Widget _buildSectionHeader(HomePalette p, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(title, style: AppFonts.bold(color: p.text, fontSize: 17)),
    );
  }

  Widget _buildScheduleCard(
    HomePalette p,
    ScheduleModel schedule, {
    required bool isUpcoming,
  }) {
    final muted = AppFonts.regular(color: p.textMuted, fontSize: 12);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: SurfaceCard(
        onTap: () => _showScheduleDetails(p, schedule),
        radius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isUpcoming ? p.heroGradient : null,
                color: isUpcoming ? null : p.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    schedule.date.day.toString(),
                    style: AppFonts.bold(
                      color: isUpcoming ? AppColors.white : p.textMuted,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    schedule.formattedDate.split(' ')[0],
                    style: AppFonts.medium(
                      color: isUpcoming ? AppColors.white : p.textMuted,
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
                      color: isUpcoming ? p.brandSoft : p.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      schedule.classNumber,
                      style: AppFonts.semiBold(
                        color: isUpcoming ? p.brand : p.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Title
                  Text(
                    schedule.title,
                    style: AppFonts.semiBold(color: p.text, fontSize: 15),
                  ),

                  const SizedBox(height: 4),

                  // Time and faculty (the faculty name drops to its own line
                  // when it doesn't fit beside the time)
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clock, size: 14, color: p.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(schedule.formattedTime, style: muted),
                          ),
                        ],
                      ),
                      if (schedule.facultyName != null &&
                          schedule.facultyName!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.userRound,
                              size: 14,
                              color: p.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(schedule.facultyName!, style: muted),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Status icon or reminder button
            if (isUpcoming)
              PressableScale(
                pressedScale: 0.85,
                haptic: true,
                child: IconButton(
                  icon: const Icon(LucideIcons.bellRing),
                  color: p.brand,
                  onPressed: () => _setReminder(schedule),
                  tooltip: 'Set Reminder',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.circleCheck,
                  color: p.textMuted,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDetails(HomePalette p, ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(schedule.title, style: AppFonts.bold(color: p.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                p,
                LucideIcons.presentation,
                schedule.classNumber,
              ),
              _buildDetailRow(p, LucideIcons.calendar, schedule.formattedDate),
              _buildDetailRow(p, LucideIcons.clock, schedule.formattedTime),
              if (schedule.facultyName != null &&
                  schedule.facultyName!.isNotEmpty)
                _buildDetailRow(
                  p,
                  LucideIcons.userRound,
                  schedule.facultyName!,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Close', style: AppFonts.medium(color: p.brand)),
            ),
            if (schedule.isUpcoming)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _setReminder(schedule);
                },
                icon: const Icon(LucideIcons.bellRing, size: 18),
                label: const Text('Set Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.brand,
                  foregroundColor: p.card,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(HomePalette p, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: p.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppFonts.regular(color: p.text)),
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
        AppSnackBar.show(
          context,
          message:
              'Reminder set! We\'ll let you know when this session starts.',
          color: AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'We couldn\'t set the reminder. Please try again.',
          color: AppColors.danger,
        );
      }
    }
  }
}
