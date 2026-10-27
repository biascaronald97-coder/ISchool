# Classly

A Flutter class planner for students. Add a class with its weekday, time,
instructor, room, and reminder lead time. Your weekly schedule is saved locally,
and optional repeating notifications remind you before each class.

## Run the app

```sh
flutter pub get
flutter run
```

## Reminders

The app requests notification permission when a schedule with reminders is
saved. Reminders repeat weekly on Android and iOS. They use inexact scheduling
so Android does not need exact-alarm access. If notifications are denied,
classes are still saved and can be edited later.

Schedule data stays on the device. The initial schedule contains editable
sample classes; replace or remove them to make the timetable your own.
