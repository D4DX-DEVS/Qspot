import 'package:flutter/foundation.dart';

import '../../speaker/model/speaker_model.dart';
import '../model/question_model.dart';
import '../service/question_service.dart';

/// Screen-local state for the ask-a-question sheet: the chosen faculty and
/// the submitting flag, plus the submit call itself.
class AskQuestionScreenProvider extends ChangeNotifier {
  SpeakerModel? _selectedFaculty;
  bool _isSubmitting = false;

  SpeakerModel? get selectedFaculty => _selectedFaculty;
  bool get isSubmitting => _isSubmitting;

  void selectFaculty(SpeakerModel? value) {
    _selectedFaculty = value;
    notifyListeners();
  }

  void startSubmitting() {
    _isSubmitting = true;
    notifyListeners();
  }

  /// Sends the question; the caller resets state via [finishSubmitting].
  Future<void> submit({required String subject, required String description}) {
    return QuestionService.submit(
      QuestionModel(
        subject: subject,
        description: description,
        faculty: _selectedFaculty!.id,
      ),
    );
  }

  /// Ends the submitting state; [clearFaculty] is true after a success.
  void finishSubmitting({bool clearFaculty = false}) {
    if (clearFaculty) _selectedFaculty = null;
    _isSubmitting = false;
    notifyListeners();
  }
}
