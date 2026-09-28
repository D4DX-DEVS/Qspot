import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../services/course_service.dart';
import '../../../themes/app_theme.dart';
import '../../../themes/app_fonts.dart';

/// "About this course" popup: close on the left, centred title, then the course
/// story and what the student will learn.
class AboutCourseSheet extends StatelessWidget {
  const AboutCourseSheet({super.key, required this.course});

  final CourseModel course;

  static Future<void> show(BuildContext context, CourseModel course) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AboutCourseSheet(course: course),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.86,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'About this course',
                    style: AppFonts.bold(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  if (course.image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: course.image,
                        height: 168,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  if (course.image.isNotEmpty) const SizedBox(height: 18),
                  Text(
                    course.title,
                    style: AppFonts.bold(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      height: 1.25,
                    ),
                  ),
                  if (course.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      course.subtitle,
                      style: AppFonts.regular(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (course.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      course.description,
                      style: AppFonts.regular(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (course.learnPoints.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Text(
                      'What you will learn in this course:',
                      style: AppFonts.bold(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...course.learnPoints.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 8, right: 12),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point,
                                style: AppFonts.regular(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
