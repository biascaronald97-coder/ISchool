import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ischool_schedule/main.dart';
import 'package:ischool_schedule/notification_service.dart';
import 'package:ischool_schedule/schedule_class.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestNotificationService extends LocalNotificationService {
  @override
  Future<bool> syncSchedule(List<ScheduleClass> classes) async => true;
}

void main() {
  test('class times and saved schedules round-trip', () {
    const item = ScheduleClass(
      id: 'biology',
      name: 'Introduction to Biology',
      instructor: 'Dr. Chen',
      location: 'Science Hall 204',
      weekday: 1,
      startMinutes: 8 * 60 + 30,
      endMinutes: 9 * 60 + 45,
      reminderMinutes: 10,
      colorIndex: 0,
    );

    final decoded = ScheduleClass.decodeList(ScheduleClass.encodeList([item]));

    expect(formatMinutes(item.startMinutes), '8:30 AM');
    expect(formatMinutes(item.endMinutes), '9:45 AM');
    expect(decoded.single.toJson(), item.toJson());
  });

  testWidgets('student can add a class to their weekly schedule', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ScheduleApp(notificationService: _TestNotificationService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('ISchool'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('CLASS NAME'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Quantum Physics');
    await tester.ensureVisible(find.text('Add to schedule'));
    await tester.tap(find.text('Add to schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Quantum Physics'), findsOneWidget);
    expect(find.text('Class saved to your schedule.'), findsOneWidget);
  });
}
