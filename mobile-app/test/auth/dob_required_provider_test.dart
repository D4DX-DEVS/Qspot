import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/model/user_model.dart';
import 'package:qspot/screens/auth/provider/dob_required_provider.dart';
import 'package:qspot/services/api_client.dart';

UserModel _saved(String dob) =>
    UserModel(phone: '9876543210', name: 'Ayesha', dob: dob);

void main() {
  test('cannot save before a date is picked', () async {
    var calls = 0;
    final provider = DobRequiredProvider(
      applyUser: (_) async {},
      saveDob: (dob) async {
        calls++;
        return _saved(dob);
      },
    );

    expect(provider.canSave, isFalse);
    expect(await provider.save(), isFalse);
    expect(calls, 0);
  });

  test(
    'saves the picked date as YYYY-MM-DD and applies the saved profile',
    () async {
      String? sent;
      UserModel? applied;
      final provider = DobRequiredProvider(
        applyUser: (user) async => applied = user,
        saveDob: (dob) async {
          sent = dob;
          return _saved('2010-05-03T00:00:00.000Z');
        },
      )..setDob(DateTime(2010, 5, 3));

      expect(provider.dobText, '2010-05-03');
      expect(await provider.save(), isTrue);
      expect(sent, '2010-05-03');
      expect(applied?.hasDob, isTrue);
      expect(provider.isSaving, isFalse);
      expect(provider.errorMessage, isNull);
    },
  );

  test('shows the server message when saving is refused', () async {
    UserModel? applied;
    final provider = DobRequiredProvider(
      applyUser: (user) async => applied = user,
      saveDob: (_) async => throw ApiException(
        409,
        'Your date of birth is already saved and cannot be changed here.',
      ),
    )..setDob(DateTime(2010, 5, 3));

    expect(await provider.save(), isFalse);
    expect(
      provider.errorMessage,
      'Your date of birth is already saved and cannot be changed here.',
    );
    expect(applied, isNull);
    expect(provider.isSaving, isFalse);
    expect(provider.canSave, isTrue, reason: 'the student can try again');
  });

  test('a network failure gets a friendly message', () async {
    final provider = DobRequiredProvider(
      applyUser: (_) async {},
      saveDob: (_) async => throw Exception('socket closed'),
    )..setDob(DateTime(2010, 5, 3));

    expect(await provider.save(), isFalse);
    expect(provider.errorMessage, contains("couldn't save"));
  });

  test('picking a new date clears the old error', () async {
    final provider = DobRequiredProvider(
      applyUser: (_) async {},
      saveDob: (_) async => throw Exception('boom'),
    )..setDob(DateTime(2010, 5, 3));
    await provider.save();
    expect(provider.errorMessage, isNotNull);

    provider.setDob(DateTime(2011, 1, 1));
    expect(provider.errorMessage, isNull);
  });
}
