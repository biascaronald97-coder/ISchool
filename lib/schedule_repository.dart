import 'package:shared_preferences/shared_preferences.dart';

import 'schedule_class.dart';

class ScheduleRepository {
  static const _storageKey = 'student_schedule_v1';

  Future<List<ScheduleClass>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    if (stored != null) {
      return ScheduleClass.decodeList(stored);
    }

    const starterSchedule = [
      ScheduleClass(
        id: 'sample-101',
        name: 'Introduction to Biology',
        instructor: 'Dr. Sarah Chen',
        location: 'Science Hall · 204',
        weekday: 1,
        startMinutes: 8 * 60 + 30,
        endMinutes: 9 * 60 + 45,
        reminderMinutes: 10,
        colorIndex: 0,
      ),
      ScheduleClass(
        id: 'sample-102',
        name: 'Calculus II',
        instructor: 'Prof. Michael Lee',
        location: 'Math Building · 118',
        weekday: 1,
        startMinutes: 10 * 60,
        endMinutes: 11 * 60 + 15,
        reminderMinutes: 15,
        colorIndex: 1,
      ),
      ScheduleClass(
        id: 'sample-103',
        name: 'World Literature',
        instructor: 'Dr. Olivia James',
        location: 'Arts Center · 302',
        weekday: 2,
        startMinutes: 9 * 60,
        endMinutes: 10 * 60 + 15,
        reminderMinutes: 10,
        colorIndex: 2,
      ),
      ScheduleClass(
        id: 'sample-104',
        name: 'Computer Science',
        instructor: 'Prof. Noah Patel',
        location: 'Tech Hall · Lab 3',
        weekday: 3,
        startMinutes: 13 * 60,
        endMinutes: 14 * 60 + 30,
        reminderMinutes: 15,
        colorIndex: 3,
      ),
      ScheduleClass(
        id: 'sample-105',
        name: 'Psychology 101',
        instructor: 'Dr. Emma Wilson',
        location: 'Humanities · 210',
        weekday: 4,
        startMinutes: 11 * 60,
        endMinutes: 12 * 60 + 15,
        reminderMinutes: 5,
        colorIndex: 4,
      ),
      ScheduleClass(
        id: 'sample-106',
        name: 'Studio Art',
        instructor: 'Alex Rivera',
        location: 'Fine Arts · Studio B',
        weekday: 5,
        startMinutes: 14 * 60,
        endMinutes: 16 * 60,
        reminderMinutes: 10,
        colorIndex: 5,
      ),
    ];
    await preferences.setString(
      _storageKey,
      ScheduleClass.encodeList(starterSchedule),
    );
    return starterSchedule;
  }

  Future<void> save(List<ScheduleClass> classes) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      ScheduleClass.encodeList(classes),
    );
    if (!saved) {
      throw StateError('The schedule could not be saved on this device.');
    }
  }
}
