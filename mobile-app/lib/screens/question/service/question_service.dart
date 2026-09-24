import '../../../services/api_client.dart';
import '../model/question_model.dart';

/// Single place that posts a student question to the API. Replaces three
/// separate duplicated POST implementations that used to live in
/// AskQuestionScreen, the Settings "Ask a Question" dialog, and the speaker
/// detail screen.
class QuestionService {
  static Future<void> submit(QuestionModel question) async {
    await ApiClient.post('/api/questions', body: question.toJson());
  }
}
