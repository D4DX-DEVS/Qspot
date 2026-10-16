import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qspot/screens/schedule/provider/schedule_provider.dart';

void main() {
  Future<Uri?> askedFor(String? userClass) async {
    Uri? asked;
    final schedules = ScheduleProvider(loadClass: () async => userClass);
    await http.runWithClient(
      schedules.fetchSchedules,
      () => MockClient((request) async {
        asked = request.url;
        return http.Response('[]', 200);
      }),
    );
    return asked;
  }

  test('the schedule asks for the student\'s own class only', () async {
    final asked = await askedFor('8');
    expect(asked?.path, endsWith('/api/schedules'));
    expect(asked?.queryParameters['class'], '8');
  });

  test('without a class (a teacher) every session is listed', () async {
    final asked = await askedFor(null);
    expect(asked?.queryParameters.containsKey('class'), isFalse);
  });
}
