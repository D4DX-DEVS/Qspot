import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';
import '../../assignment/model/assignment_model.dart';
import '../../assignment/screens/assignment_detail_screen.dart';
import '../../common/widgets/home_theme_scope.dart';
import '../../course/screens/course_screen.dart';
import '../../lesson/screens/lesson_screen.dart';
import '../../subject/provider/subject_provider.dart';
import '../../video/provider/video_provider.dart';
import '../model/notification_target.dart';

/// Opens the screen a notification points to. Used by the notification list
/// and, once a push service is connected, by a tap on a push.
class NotificationTargetOpener {
  /// False when the item is not on this phone's lists (for example a lesson
  /// that was removed), so the caller can show the message instead.
  static Future<bool> open(
    BuildContext context,
    NotificationTarget target, {
    String title = '',
  }) async {
    switch (target.kind) {
      case 'lesson':
        final video = context.read<VideoProvider>().getVideoById(target.id);
        if (video == null) return false;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HomeThemeScope(child: LessonScreen(video: video)),
          ),
        );
        return true;
      case 'course':
        final courses = context.read<SubjectProvider>().courses;
        final matches = courses.where((c) => c.id == target.id);
        if (matches.isEmpty) return false;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                HomeThemeScope(child: CourseScreen(course: matches.first)),
          ),
        );
        return true;
      case 'assignment':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssignmentDetailScreen(
              assignment: AssignmentModel(id: target.id, title: title),
            ),
          ),
        );
        return true;
      case 'quiz':
        // A quiz starts from the list, after choosing its language.
        await Navigator.of(context).pushNamed(AppRoutes.quizzes);
        return true;
    }
    return false;
  }
}
