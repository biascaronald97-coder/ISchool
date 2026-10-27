import 'dart:convert';

const weekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class ScheduleClass {
  const ScheduleClass({
    required this.id,
    required this.name,
    required this.instructor,
    required this.location,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.reminderMinutes,
    required this.colorIndex,
  });

  final String id;
  final String name;
  final String instructor;
  final String location;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final int reminderMinutes;
  final int colorIndex;

  ScheduleClass copyWith({
    String? id,
    String? name,
    String? instructor,
    String? location,
    int? weekday,
    int? startMinutes,
    int? endMinutes,
    int? reminderMinutes,
    int? colorIndex,
  }) {
    return ScheduleClass(
      id: id ?? this.id,
      name: name ?? this.name,
      instructor: instructor ?? this.instructor,
      location: location ?? this.location,
      weekday: weekday ?? this.weekday,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'instructor': instructor,
    'location': location,
    'weekday': weekday,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'reminderMinutes': reminderMinutes,
    'colorIndex': colorIndex,
  };

  factory ScheduleClass.fromJson(Map<String, dynamic> json) {
    return ScheduleClass(
      id: json['id'] as String,
      name: json['name'] as String,
      instructor: json['instructor'] as String? ?? '',
      location: json['location'] as String? ?? '',
      weekday: json['weekday'] as int,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
      reminderMinutes: json['reminderMinutes'] as int? ?? 10,
      colorIndex: json['colorIndex'] as int? ?? 0,
    );
  }

  static List<ScheduleClass> decodeList(String value) {
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((item) => ScheduleClass.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<ScheduleClass> classes) =>
      jsonEncode(classes.map((item) => item.toJson()).toList());
}

String formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}
