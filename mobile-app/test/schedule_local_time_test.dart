import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:qspot/screens/schedule/model/schedule_model.dart';

void main() {
  test('a class time from the server is shown in the phone\'s local time', () {
    final schedule = ScheduleModel.fromJson({
      '_id': 's1',
      'title': 'Live class',
      'scheduleDate': '2026-10-20T04:30:00.000Z',
    });
    final local = DateTime.utc(2026, 10, 20, 4, 30).toLocal();

    expect(schedule.date.isUtc, isFalse);
    expect(schedule.date.isAtSameMomentAs(local), isTrue);
    expect(schedule.formattedTime, DateFormat('hh:mm a').format(local));
    expect(schedule.date.day, local.day);
  });
}
