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
    return 'Correct answers show after ${_when(at, now)}, once everyone has '
        'finished.';
  }

  /// Shown instead of the score after submitting: the score is held back
  /// with the answers until the quiz closes for everyone.
  String submittedMessage({DateTime? now}) {
    final at = availableAt;
    final later = at == null
        ? 'once the quiz has closed.'
        : 'after ${_when(at, now)}, once everyone has finished.';
    return 'Your answers have been submitted. Your score will show $later';
  }

  /// "5:05 pm today" or "5:05 pm on 21 Oct".
  static String _when(DateTime at, DateTime? now) {
    final today = now ?? DateTime.now();
    final sameDay =
        at.year == today.year && at.month == today.month && at.day == today.day;
    final time = DateFormat('h:mm a').format(at).toLowerCase();
    final day = sameDay ? 'today' : 'on ${DateFormat('d MMM').format(at)}';
    return '$time $day';
  }
}
