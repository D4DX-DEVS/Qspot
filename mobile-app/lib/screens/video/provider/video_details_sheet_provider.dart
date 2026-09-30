import 'package:flutter/foundation.dart';

import '../../../services/video_progress_service.dart';

/// Screen-local state for the episode details sheet: loads the practice
/// questions for one video and tracks whether that load is still running.
class VideoDetailsSheetProvider extends ChangeNotifier {
  List<VideoQuestionItem> _questions = [];
  bool _loadingQuestions = true;
  bool _disposed = false;

  List<VideoQuestionItem> get questions => _questions;
  bool get loadingQuestions => _loadingQuestions;

  Future<void> loadQuestions(String videoId) async {
    final questions = await VideoProgressService.questions(videoId);
    if (_disposed) return;
    _questions = questions;
    _loadingQuestions = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
