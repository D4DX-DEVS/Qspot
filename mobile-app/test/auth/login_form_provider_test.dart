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
    test('is not complete until the phone has 10 digits and a date is set', () {
      final form = LoginFormProvider();
      expect(form.isComplete, isFalse);

      form.setPhone('98765');
      form.setDob(DateTime(2010, 5, 3));
      expect(form.isComplete, isFalse, reason: 'short phone');

      form.setPhone('9876543210');
      expect(form.isComplete, isTrue);
    });

    test('a phone alone is not enough', () {
      final form = LoginFormProvider()..setPhone('9876543210');
      expect(form.isComplete, isFalse);
      expect(form.dobForApi, isNull);
    });

    test('the date goes to the API as YYYY-MM-DD', () {
      final form = LoginFormProvider()..setDob(DateTime(2010, 5, 3));
      expect(form.dobForApi, '2010-05-03');
    });

    test('only notifies when something changed', () {
      final form = LoginFormProvider();
      var notified = 0;
      form.addListener(() => notified++);

      form.setPhone('9');
      form.setPhone('9');
      expect(notified, 1);
    });
  });
}
