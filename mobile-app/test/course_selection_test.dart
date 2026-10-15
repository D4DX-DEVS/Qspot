import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/model/user_model.dart';
import 'package:qspot/screens/course_selection/model/needs_course_choice.dart';
import 'package:qspot/screens/course_selection/provider/course_selection_provider.dart';
import 'package:qspot/screens/course_selection/widgets/choose_courses_prompt.dart';
import 'package:qspot/services/api_client.dart';
import 'package:qspot/services/course_service.dart';

const _tajweed = CourseModel(id: 'c1', title: 'Tajweed');
const _fiqh = CourseModel(id: 'c2', title: 'Fiqh Basics');

UserModel _user(List<String> courseIds) =>
    UserModel(phone: '1', courseIds: courseIds);

CourseSelectionProvider _provider({
  Future<List<CourseModel>> Function()? fetch,
  Future<UserModel> Function(List<String>)? save,
  Future<void> Function(UserModel)? apply,
  Set<String> initial = const {},
}) => CourseSelectionProvider(
  initialSelection: initial,
  fetchCourses: fetch ?? () async => [_tajweed, _fiqh],
  saveCourses: save ?? (ids) async => _user(ids),
  applyUser: apply ?? (_) async {},
);

void main() {
  group('needsCourseChoice', () {
    test('asks a learner with no courses and no lessons', () {
      expect(needsCourseChoice(courseIds: const [], listsEmpty: true), isTrue);
    });

    test('does not ask once there are lessons, even with an old profile', () {
      expect(
        needsCourseChoice(courseIds: const [], listsEmpty: false),
        isFalse,
      );
    });

    test('does not ask a learner who already chose a course', () {
      expect(
        needsCourseChoice(courseIds: const ['c1'], listsEmpty: true),
        isFalse,
      );
    });
  });

  group('CourseSelectionProvider', () {
    test('lists every course on offer', () async {
      final provider = _provider();
      expect(provider.isLoading, isTrue);

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.courses.map((c) => c.id), ['c1', 'c2']);
      expect(provider.errorMessage, isNull);
    });

    test('starts with the courses already chosen', () async {
      final provider = _provider(initial: {'c2'});
      await provider.load();

      expect(provider.selected, {'c2'});
      expect(provider.canSave, isTrue);
    });

    test('nothing ticked cannot be saved', () async {
      var saveCalls = 0;
      final provider = _provider(
        save: (ids) async {
          saveCalls++;
          return _user(ids);
        },
      );
      await provider.load();

      expect(provider.canSave, isFalse);
      expect(await provider.save(), isFalse);
      expect(saveCalls, 0);
    });

    test('ticking and unticking changes what can be saved', () async {
      final provider = _provider();
      await provider.load();

      provider.toggle('c1', true);
      expect(provider.canSave, isTrue);
      provider.toggle('c1', false);
      expect(provider.canSave, isFalse);
    });

    test('saves the ticked courses and hands the profile back', () async {
      List<String>? sent;
      UserModel? applied;
      final provider = _provider(
        save: (ids) async {
          sent = ids;
          return _user(ids);
        },
        apply: (user) async => applied = user,
      );
      await provider.load();
      provider.toggle('c1', true);
      provider.toggle('c2', true);

      final saved = await provider.save();

      expect(saved, isTrue);
      expect(sent, ['c1', 'c2']);
      expect(applied?.courseIds, ['c1', 'c2']);
      expect(provider.isSaving, isFalse);
    });

    test('a server message from a failed save is shown', () async {
      final provider = _provider(
        save: (_) async => throw ApiException(400, 'courseIds is invalid'),
      );
      await provider.load();
      provider.toggle('c1', true);

      expect(await provider.save(), isFalse);

      expect(provider.errorMessage, 'courseIds is invalid');
      expect(provider.isSaving, isFalse);
    });

    test('any other failed save shows a plain message', () async {
      final provider = _provider(save: (_) async => throw Exception('boom'));
      await provider.load();
      provider.toggle('c1', true);

      expect(await provider.save(), isFalse);

      expect(provider.errorMessage, contains("couldn't update your courses"));
    });

    test('a failed load shows a message and can be retried', () async {
      var attempts = 0;
      final provider = _provider(
        fetch: () async {
          attempts++;
          if (attempts == 1) throw Exception('offline');
          return [_tajweed];
        },
      );

      await provider.load();
      expect(provider.errorMessage, isNotNull);
      expect(provider.courses, isEmpty);

      await provider.load();
      expect(provider.errorMessage, isNull);
      expect(provider.courses, hasLength(1));
    });
  });

  testWidgets('the prompt explains the empty app and offers the picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChooseCoursesPrompt())),
    );

    expect(find.text('Choose Your Courses'), findsOneWidget);
    expect(
      find.text(
        'Pick the courses you are taking and your lessons will appear here.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Choose Courses'), findsOneWidget);
  });
}
