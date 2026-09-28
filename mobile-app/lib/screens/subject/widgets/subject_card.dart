import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/subject_model.dart';
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
    return Semantics(
      label: totalLessons > 0
          ? 'Open chapter ${subject.displayName}, $completedLessons of $totalLessons lessons complete'
          : 'Open chapter ${subject.displayName}',
      button: true,
      child: SizedBox(
        width: width,
        height: height,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Stack(
              children: [
                // Background Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: subject.imageUrl == null
                      ? Container(
                          color: AppTheme.surfaceAlt,
                          child: Icon(
                            Icons.book,
                            size: 32,
                            color: AppTheme.secondaryGray,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: subject.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.surfaceAlt,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.gradientEnd,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.surfaceAlt,
                            child: Icon(
                              Icons.book,
                              size: 32,
                              color: AppTheme.secondaryGray,
                            ),
                          ),
                        ),
                ),

                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),

                if (totalLessons > 0)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 34,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: (completedLessons / totalLessons).clamp(
                          0.0,
                          1.0,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.35),
                        color: AppTheme.accentAmber,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingSmall),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject.displayName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppTheme.primaryWhite,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (totalLessons > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '$completedLessons/$totalLessons',
                            style: AppFonts.extraBold(
                              color: Colors.white,
                              fontSize: 10,
                            ),
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
    );
  }
}
