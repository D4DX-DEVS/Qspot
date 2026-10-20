import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/model/phone_country_list.dart';
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
    test('a student is complete with a name and a 10-digit phone', () {
      final form = LoginFormProvider();
      expect(form.isComplete, isFalse);

      form.setPhone('98765');
      form.setName('Ramu K');
      expect(form.isComplete, isFalse, reason: 'short phone');

      form.setPhone('9876543210');
      expect(form.isComplete, isTrue);
      expect(form.nameForApi, 'Ramu K');
    });

    test('the chosen country decides how many digits the phone needs', () {
      final form = LoginFormProvider()
        ..setName('Ramu K')
        ..setPhone('501234567');
      expect(form.isComplete, isFalse, reason: 'India needs 10 digits');

      form.setCountry(
        phoneCountries.firstWhere((country) => country.iso == 'AE'),
      );
      expect(form.isComplete, isTrue, reason: 'a UAE number has 9');
      expect(form.phoneForApi, '+971501234567');
    });

    test('a phone alone, or a blank name, is not enough', () {
      final form = LoginFormProvider()..setPhone('9876543210');
      expect(form.isComplete, isFalse);

      form.setName('   ');
      expect(form.isComplete, isFalse);
      expect(form.dobForApi, isNull);
    });

    test('a teacher needs a date of birth, not a name', () {
      final form = LoginFormProvider()
        ..setPhone('9876543210')
        ..setName('Ramu K')
        ..toggleTeacher();
      expect(form.isTeacher, isTrue);
      expect(form.isComplete, isFalse, reason: 'a name is not a date');
      expect(form.nameForApi, isNull, reason: 'a teacher never sends a name');

      form.setDob(DateTime(1985, 4, 12));
      expect(form.isComplete, isTrue);
      expect(form.dobForApi, '1985-04-12');
    });

    test('switching back clears the date and sends the kept name', () {
      final form = LoginFormProvider()
        ..setName('Ramu K')
        ..toggleTeacher()
        ..setDob(DateTime(1985, 4, 12))
        ..toggleTeacher();
      expect(form.isTeacher, isFalse);
      expect(form.dobForApi, isNull);
      expect(form.nameForApi, 'Ramu K');
    });

    test('the missing-date message shows only after "Sign In" is tapped', () {
      final form = LoginFormProvider()..toggleTeacher();
      expect(form.dobError, isNull);

      form.markSubmitted();
      expect(form.submitted, isTrue);
      expect(form.dobError, 'Please choose your date of birth');

      form.setDob(DateTime(1985, 4, 12));
      expect(form.dobError, isNull);
    });

    test('only notifies when the phone or name changed', () {
      final form = LoginFormProvider();
      var notified = 0;
      form.addListener(() => notified++);

      form.setPhone('9');
      form.setPhone('9');
      form.setName('R');
      form.setName('R');
      expect(notified, 2);
    });
  });
}
