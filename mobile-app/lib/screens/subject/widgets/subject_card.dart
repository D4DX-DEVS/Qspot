import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/subject_model.dart';
import '../../../widgets/animation/animated_progress_bar.dart';
import '../../../widgets/animation/pressable_scale.dart';
import '../../../widgets/common/fit_text.dart';
import '../../../themes/app_colors.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final int completedLessons;
  final int totalLessons;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.width = 120,
    this.height = 160,
    this.completedLessons = 0,
    this.totalLessons = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = subject.imageUrl != null;
    final hasProgress = totalLessons > 0;
    final isComplete = hasProgress && completedLessons >= totalLessons;
    return Semantics(
      label: totalLessons > 0
          ? 'Open chapter ${subject.displayName}, $completedLessons of $totalLessons lessons complete'
          : 'Open chapter ${subject.displayName}',
      button: true,
      child: SizedBox(
        width: width,
        height: height,
        child: PressableScale(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: LayoutBuilder(
                builder: (context, tile) => Stack(
                  children: [
                    // Background Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: subject.imageUrl == null
                          ? Container(
                              color: scheme.primaryContainer,
                              child: Icon(
                                LucideIcons.book,
                                size: 32,
                                color: scheme.onSurfaceVariant,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: subject.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: scheme.primaryContainer,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: scheme.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: scheme.primaryContainer,
                                child: Icon(
                                  LucideIcons.book,
                                  size: 32,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),

                    // Gradient Overlay. The server artwork already carries the
                    // chapter name, so with a picture only the strip behind the
                    // progress bar is darkened; the picture stays crisp above it.
                    if (!hasImage || hasProgress)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: hasImage ? const [0, 0.74, 1] : null,
                            colors: [
                              AppColors.transparent,
                              if (hasImage) AppColors.transparent,
                              AppColors.black.withValues(
                                alpha: hasImage ? 0.7 : 0.55,
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (isComplete)
                      Positioned(
                        top: AppTheme.paddingSmall,
                        right: AppTheme.paddingSmall,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppColors.accentAmber,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(
                              LucideIcons.check,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingSmall),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!hasImage)
                              // Shrinks a long name so it stays inside the picture.
                              FitText(
                                subject.displayName,
                                maxHeight: tile.maxHeight * 0.55,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                              ),
                            if (hasProgress) ...[
                              if (!hasImage) const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: AnimatedProgressBar(
                                        minHeight: 5,
                                        value: (completedLessons / totalLessons)
                                            .clamp(0.0, 1.0),
                                        backgroundColor: AppColors.white
                                            .withValues(alpha: 0.35),
                                        color: AppColors.accentAmber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$completedLessons/$totalLessons',
                                    style: AppFonts.extraBold(
                                      color: AppColors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
