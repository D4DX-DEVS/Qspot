import '../../../services/video_progress_service.dart';
import '../../quiz/model/answers_availability.dart';
import '../../quiz/model/quiz_model.dart';

/// What the practice result says: for a try just submitted, its own score;
/// for a saved result opened later, the best try.
class PracticeResultSummary {
  const PracticeResultSummary(this.result, {required this.justSubmitted});

  final VideoQuizResult result;
  final bool justSubmitted;

  int get shownScore =>
      justSubmitted ? (result.latestScore ?? result.score) : result.score;

  int get shownPercentage => justSubmitted
      ? (result.latestPercentage ?? result.percentage)
      : result.percentage;

  String get scoreLine => justSubmitted
      ? 'You answered $shownScore of ${result.totalQuestions} correctly.'
      : 'Your best: ${result.score} of ${result.totalQuestions} correct.';

  /// The best score and how many tries, once there has been more than one.
  String? get triesLine {
    if (result.attemptCount < 2) return null;
    final tries = '${result.attemptCount} tries';
    return justSubmitted
        ? 'Best so far: ${result.score} of ${result.totalQuestions} · $tries'
        : tries;
  }

  bool get canReview => result.answersRevealed && result.results.isNotEmpty;

  AnswersAvailability get answers => AnswersAvailability(
    revealed: result.answersRevealed,
    availableAt: result.answersAvailableAt,
  );

  /// The best try's answers in the shape the answer review screen shows.
  List<QuestionResult> get reviewResults => [
    for (final r in result.results)
      QuestionResult(
        questionId: r.questionId,
        type: r.type,
        questionEn: r.questionEn,
        questionMl: r.questionMl,
        optionsEn: r.optionsEn,
        optionsMl: r.optionsMl,
        attemptedAnswer: int.tryParse(r.attemptedAnswer),
        correctAnswer: int.tryParse(r.correctAnswer) ?? -1,
        isCorrect: r.isCorrect,
      ),
  ];
}
