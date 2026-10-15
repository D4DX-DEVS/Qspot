import '../screens/quiz/model/quiz_model.dart';
import 'api_client.dart';

/// One of the learner's finished exam attempts. Per-question results come
/// back only once the exam has closed for everyone.
class QuizAttemptService {
  static Future<QuizAttemptResult> fetch(String attemptId) async {
    final body = await ApiClient.get('/api/user/quiz-attempts/$attemptId');
    return QuizAttemptResult.fromJson(Map<String, dynamic>.from(body as Map));
  }
}
