import 'package:intl/intl.dart';

/// When a learner may see the correct answers to an exam or a practice set.
///
/// The server decides (answers stay hidden until nobody can still submit) and
/// sends `answersRevealed` and `answersAvailableAt`; this only words it.
class AnswersAvailability {
  const AnswersAvailability({required this.revealed, this.availableAt});

  final bool revealed;

  /// When the answers become visible; null means they never will (practice
  /// with no end date).
  final DateTime? availableAt;

  /// The line shown in place of the answers while they are hidden.
  String hiddenMessage({DateTime? now}) {
    final at = availableAt;
    if (at == null) {
      return "Correct answers aren't shown for this one, so it stays fair "
          'for everyone.';
    }
    final today = now ?? DateTime.now();
    final sameDay =
        at.year == today.year && at.month == today.month && at.day == today.day;
    final time = DateFormat('h:mm a').format(at).toLowerCase();
    final day = sameDay ? 'today' : 'on ${DateFormat('d MMM').format(at)}';
    return 'Correct answers show after $time $day, once everyone has '
        'finished.';
  }
}
