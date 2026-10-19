import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/provider/login_form_provider.dart';
import 'package:qspot/utils/dob_format.dart';

void main() {
  group('formatDobForApi', () {
    test('writes YYYY-MM-DD with zero padding', () {
      expect(formatDobForApi(DateTime(2010, 5, 3)), '2010-05-03');
      expect(formatDobForApi(DateTime(2008, 12, 31)), '2008-12-31');
    });
  });

  group('LoginFormProvider', () {
    test('a student is complete with a 10-digit phone and a class', () {
      final form = LoginFormProvider();
      expect(form.isComplete, isFalse);

      form.setPhone('98765');
      form.setClassNumber('9');
      expect(form.isComplete, isFalse, reason: 'short phone');

      form.setPhone('9876543210');
      expect(form.isComplete, isTrue);
    });

    test('a phone alone is not enough', () {
      final form = LoginFormProvider()..setPhone('9876543210');
      expect(form.isComplete, isFalse);
      expect(form.classNumber, isNull);
      expect(form.dobForApi, isNull);
    });

    test('a teacher needs a date of birth, not a class', () {
      final form = LoginFormProvider()
        ..setPhone('9876543210')
        ..toggleTeacher();
      expect(form.isTeacher, isTrue);
      expect(form.isComplete, isFalse);

      form.setClassNumber('9');
      expect(form.isComplete, isFalse, reason: 'a class is not a date');

      form.setDob(DateTime(1985, 4, 12));
      expect(form.isComplete, isTrue);
      expect(form.dobForApi, '1985-04-12');
    });

    test('switching clears the other way, so only one is ever sent', () {
      final form = LoginFormProvider()..setClassNumber('9');
      form.toggleTeacher();
      expect(form.classNumber, isNull);

      form.setDob(DateTime(1985, 4, 12));
      form.toggleTeacher();
      expect(form.isTeacher, isFalse);
      expect(form.dobForApi, isNull);
    });

    test('only notifies when the phone changed', () {
      final form = LoginFormProvider();
      var notified = 0;
      form.addListener(() => notified++);

      form.setPhone('9');
      form.setPhone('9');
      expect(notified, 1);
    });
  });
}
