import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/quiz/provider/quiz_provider.dart';

/// Exercises the submission payload building logic in [QuizProvider]
/// without hitting the network. This targets the bug where the old
/// implementation used `int.tryParse` on a Mongo ObjectId hex string
/// (always failing) and fell back to a `DateTime.now().millisecondsSinceEpoch`
/// synthetic id that could collide across questions, making one answer
/// selection silently answer multiple questions.
void main() {
  group('QuizProvider answers payload', () {
    test('keys answers by the question _id string, not a parsed int', () {
      final provider = QuizProvider();
      _seedSession(provider, [
        _q('66f1a2b3c4d5e6f7a8b9c0d1'),
        _q('66f1a2b3c4d5e6f7a8b9c0d2'),
      ]);

      provider.selectAnswer(2); // answers question at currentQuestionIndex (0)
      provider.nextQuestion();
      provider.selectAnswer(1);

      final payload = provider.buildAnswersPayload();

      expect(payload, hasLength(2));
      expect(payload[0]['questionId'], '66f1a2b3c4d5e6f7a8b9c0d1');
      expect(payload[0]['questionId'], isA<String>());
      expect(payload[0]['attemptedAnswer'], 2);
      expect(payload[1]['questionId'], '66f1a2b3c4d5e6f7a8b9c0d2');
      expect(payload[1]['attemptedAnswer'], 1);
    });

    test(
      'an unanswered question sends a null attemptedAnswer, not -1 or a synthetic value',
      () {
        final provider = QuizProvider();
        _seedSession(provider, [_q('a1'), _q('a2'), _q('a3')]);

        provider.selectAnswer(0); // only answers question a1

        final payload = provider.buildAnswersPayload();

        expect(payload[0]['attemptedAnswer'], 0);
        expect(payload[1]['attemptedAnswer'], isNull);
        expect(payload[2]['attemptedAnswer'], isNull);
      },
    );

    test('selecting an answer never collides across distinct question ids', () {
      final provider = QuizProvider();
      _seedSession(provider, [_q('id-1'), _q('id-2'), _q('id-3')]);

      provider.selectAnswer(3);
      provider.goToQuestion(1);
      provider.selectAnswer(0);
      provider.goToQuestion(2);
      provider.selectAnswer(2);

      expect(provider.getSelectedAnswer('id-1'), 3);
      expect(provider.getSelectedAnswer('id-2'), 0);
      expect(provider.getSelectedAnswer('id-3'), 2);
    });
  });
}

Map<String, dynamic> _q(String id) => {
  '_id': id,
  'type': 'multiple_choice',
  'question_en': 'Q $id',
  'options_en': ['A', 'B', 'C', 'D'],
  'difficulty': 'easy',
};

/// Seeds an active session on [provider] the same way [QuizProvider.startQuiz]
/// would, without making a network call — reaches into the same code path
/// via the public API surface (selectAnswer/goToQuestion) after constructing
/// questions through the real [QuizQuestion.fromJson] parser indirectly by
/// exercising a fresh provider and its private state through its public
/// getters only.
void _seedSession(
  QuizProvider provider,
  List<Map<String, dynamic>> questionsJson,
) {
  // QuizProvider only exposes session mutation via startQuiz (network) in
  // production; for a pure unit test we drive it through the same public
  // shape it would end up in after a successful startQuiz by using the
  // testing seam below.
  provider.seedSessionForTest(questionsJson);
}
