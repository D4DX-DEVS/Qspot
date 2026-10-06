import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/model/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('reads id from the contract shape ("id")', () {
      final user = UserModel.fromJson({
        'id': 'abc123',
        'phone': '9876543210',
        'name': 'Ayesha',
        'class': '9',
        'email': 'ayesha@example.com',
        'role': 'student',
        'dob': '2012-05-01',
        'language': 'en',
      });

      expect(user.id, 'abc123');
      expect(user.phone, '9876543210');
      expect(user.name, 'Ayesha');
      expect(user.classNumber, '9');
      expect(user.email, 'ayesha@example.com');
      expect(user.role, 'student');
      expect(user.dob, '2012-05-01');
      expect(user.language, 'en');
    });

    test('falls back to raw Mongo "_id" when "id" is absent', () {
      final user = UserModel.fromJson({
        '_id': 'mongo-object-id',
        'phone': '9876543210',
      });

      expect(user.id, 'mongo-object-id');
    });

    test('prefers "id" over "_id" when both are present', () {
      final user = UserModel.fromJson({
        'id': 'contract-id',
        '_id': 'mongo-object-id',
        'phone': '9876543210',
      });

      expect(user.id, 'contract-id');
    });

    test('id is null when neither "id" nor "_id" is present', () {
      final user = UserModel.fromJson({'phone': '9876543210'});
      expect(user.id, isNull);
    });

    test('parses nested consent map when present', () {
      final user = UserModel.fromJson({
        'id': 'abc123',
        'phone': '9876543210',
        'consent': {'by': 'parent', 'name': 'Fathima'},
      });

      expect(user.consent, isNotNull);
      expect(user.consent!['by'], 'parent');
      expect(user.consent!['name'], 'Fathima');
    });

    test('consent is null when absent or not a map', () {
      final user = UserModel.fromJson({'phone': '9876543210'});
      expect(user.consent, isNull);
    });

    test('toJson round-trips id, dob, consent and language', () {
      final original = UserModel.fromJson({
        'id': 'abc123',
        'phone': '9876543210',
        'name': 'Ayesha',
        'class': '9',
        'dob': '2012-05-01',
        'consent': {'by': 'school', 'name': 'Green Valley'},
        'language': 'ml',
        'token': 'tok-1',
      });

      final roundTripped = UserModel.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.phone, original.phone);
      expect(roundTripped.dob, original.dob);
      expect(roundTripped.consent, original.consent);
      expect(roundTripped.language, original.language);
      expect(roundTripped.token, original.token);
    });

    test('parses and resolves a profile image URL', () {
      final user = UserModel.fromJson({
        'phone': '9876543210',
        'profileImage': '/uploads/profile/student.jpg',
      });

      expect(user.profileImage, '/uploads/profile/student.jpg');
      expect(user.profileImageUrl, endsWith('/uploads/profile/student.jpg'));
      expect(user.toJson()['profileImage'], '/uploads/profile/student.jpg');
    });
  });
}
