import 'quiz_progress_record.dart';

/// Why a student's answers were refused, in plain words for the Quiz page.
class QuizRefusal {
  QuizRefusal._();

  static String message(QuizProgressRecord record) {
    final quiz = record.title.isEmpty ? 'your quiz' : '"${record.title}"';
    final code = record.rejectedCode;
    if (code == QuizProgressRecord.tooLateCode) {
      return 'Your answers for $quiz reached us after the quiz closed, so they '
          'could not be marked. Please speak to your teacher.';
    }
    if (code == QuizProgressRecord.switchedOffCode) {
      return "Your answers for $quiz couldn't be submitted because the quiz "
          'was switched off. Please speak to your teacher.';
    }
    if (code == QuizProgressRecord.removedCode) {
      return "Your answers for $quiz couldn't be submitted because the quiz "
          'was removed. Please speak to your teacher.';
    }
    if (record.canRetake) {
      return "Your answers for $quiz couldn't be submitted because the quiz's "
          'questions were changed after you started.';
    }
    return "Your answers for $quiz couldn't be submitted. Please speak to "
        'your teacher.';
  }
}
