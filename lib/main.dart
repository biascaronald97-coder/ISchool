import 'package:flutter/material.dart';

import 'notification_service.dart';
import 'schedule_class.dart';
import 'schedule_repository.dart';

const _ink = Color(0xFF17243B);
const _muted = Color(0xFF8490A3);
const _canvas = Color(0xFFF5F7FB);
const _brand = Color(0xFF5268E8);
const _classColors = <Color>[
  Color(0xFF5268E8),
  Color(0xFFEA8D48),
  Color(0xFF29A58A),
  Color(0xFF9A69D2),
  Color(0xFFE36D83),
  Color(0xFF3996C8),
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScheduleApp());
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.repository, this.notificationService});

  final ScheduleRepository? repository;
  final LocalNotificationService? notificationService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScheduleHomePage(
            repository: widget.repository,
            notificationService: widget.notificationService,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5268E8),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 58,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'ISchool',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your schedule, simplified',
                style: TextStyle(
                  color: Color(0xFFE8ECFF),
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleApp extends StatelessWidget {
  const ScheduleApp({super.key, this.repository, this.notificationService});

  final ScheduleRepository? repository;
  final LocalNotificationService? notificationService;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brand,
      surface: Colors.white,
    );
    return MaterialApp(
      title: 'ISchool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _canvas,
        fontFamily: 'Roboto',
        textTheme: Theme.of(context).textTheme
            .apply(bodyColor: _ink, displayColor: _ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FB),
          hintStyle: const TextStyle(color: _muted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _brand, width: 1.4),
          ),
        ),
      ),
      home: SplashScreen(
        repository: repository,
        notificationService: notificationService,
      ),
    );
  }
}

class ScheduleHomePage extends StatefulWidget {
  const ScheduleHomePage({
    super.key,
    this.repository,
    this.notificationService,
  });

  final ScheduleRepository? repository;
  final LocalNotificationService? notificationService;

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  late final ScheduleRepository _repository;
  late final LocalNotificationService _notificationService;
  final _scrollController = ScrollController();
  List<ScheduleClass> _classes = [];
  bool _loading = true;
  Object? _loadError;
  late int _selectedWeekday;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ScheduleRepository();
    _notificationService =
        widget.notificationService ?? LocalNotificationService();
    _selectedWeekday = DateTime.now().weekday;
    _loadSchedule();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    try {
      final classes = await _repository.load();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  List<ScheduleClass> get _selectedDayClasses {
    final classes = _classes
        .where((item) => item.weekday == _selectedWeekday)
        .toList();
    classes.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return classes;
  }

  Future<void> _openClassForm({ScheduleClass? existing}) async {
    final result = await showModalBottomSheet<ScheduleClass>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleForm(initialClass: existing),
    );
    if (result == null || !mounted) return;

    final updated = [..._classes];
    if (existing == null) {
      updated.add(result);
    } else {
      final index = updated.indexWhere((item) => item.id == existing.id);
      if (index != -1) updated[index] = result;
    }
    await _saveSchedule(updated, 'Class saved to your schedule.');
  }

  Future<void> _deleteClass(ScheduleClass item) async {
    final updated = _classes.where((entry) => entry.id != item.id).toList();
    await _saveSchedule(updated, '${item.name} removed from your schedule.');
  }

  Future<void> _saveSchedule(
    List<ScheduleClass> updated,
    String message,
  ) async {
    try {
      await _repository.save(updated);
    } catch (error) {
      if (mounted) _showMessage('Could not save your schedule: $error');
      return;
    }
    if (!mounted) return;
    setState(() => _classes = updated);
    _showMessage(message);

    try {
      final remindersEnabled = await _notificationService.syncSchedule(updated);
      if (!mounted) return;
      if (!remindersEnabled &&
          updated.any((item) => item.reminderMinutes > 0)) {
        _showMessage(
          'Schedule saved. Allow notifications in settings to get class reminders.',
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(
          'Schedule saved, but reminders could not be updated: $error',
        );
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final dayClasses = _selectedDayClasses;
    final today = DateTime.now().weekday;
    final upcoming = dayClasses.where((item) {
      return _selectedWeekday != today ||
          item.startMinutes > DateTime.now().hour * 60 + DateTime.now().minute;
    }).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _brand))
            : _loadError != null
            ? _LoadError(error: _loadError!, onRetry: _loadSchedule)
            : RefreshIndicator(
                onRefresh: _loadSchedule,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                      sliver: SliverList.list(
                        children: [
                          _TopBar(
                            onNotificationsTap: () => _showMessage(
                              'Reminders are sent before each class.',
                            ),
                          ),
                          const SizedBox(height: 30),
                          _WelcomeHeader(
                            totalClasses: _classes.length,
                            weekday: today,
                          ),
                          const SizedBox(height: 25),
                          _WeekPicker(
                            selectedDay: _selectedWeekday,
                            onSelected: (day) =>
                                setState(() => _selectedWeekday = day),
                          ),
                          const SizedBox(height: 23),
                          if (upcoming != null) ...[
                            _NextClassCard(
                              item: upcoming,
                              onTap: () => _openClassForm(existing: upcoming),
                            ),
                            const SizedBox(height: 28),
                          ],
                          _AgendaHeader(
                            weekday: _selectedWeekday,
                            count: dayClasses.length,
                          ),
                          const SizedBox(height: 15),
                          if (dayClasses.isEmpty)
                            _EmptyDay(
                              weekday: _selectedWeekday,
                              onAdd: () => _openClassForm(),
                            )
                          else
                            ...dayClasses.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ClassCard(
                                  item: item,
                                  onTap: () => _openClassForm(existing: item),
                                  onDelete: () => _deleteClass(item),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          _FooterTip(classCount: _classes.length),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openClassForm(),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add a class',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: _brand),
        ),
        const SizedBox(width: 11),
        const Text(
          'ISchool',
          style: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onNotificationsTap,
          tooltip: 'Class reminders',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _ink,
            fixedSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 9),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8ECF8),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: const Text(
            'A',
            style: TextStyle(
              color: _brand,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.totalClasses, required this.weekday});

  final int totalClasses;
  final int weekday;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final date =
        '${weekdays[weekday - 1]}, ${_monthName(now.month)} ${now.day}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, Alex 👋',
          style: const TextStyle(
            fontSize: 27,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: _ink,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(date, style: const TextStyle(color: _muted, fontSize: 14)),
            const SizedBox(width: 10),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFBBC3D1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$totalClasses ${totalClasses == 1 ? 'class' : 'classes'} this week',
              style: const TextStyle(color: _muted, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekPicker extends StatelessWidget {
  const _WeekPicker({required this.selectedDay, required this.onSelected});

  final int selectedDay;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return Row(
      children: List.generate(7, (index) {
        final day = index + 1;
        final selected = day == selectedDay;
        final date = monday.add(Duration(days: index));
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 7),
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => onSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _brand : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _brand.withValues(alpha: 0.23),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white70 : _muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.item, required this.onTap});

  final ScheduleClass item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF72E2B5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'UP NEXT',
                    style: TextStyle(
                      color: Color(0xFFB6C2D8),
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatMinutes(item.startMinutes),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFB6C2D8),
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Color(0xFFB6C2D8),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.location.isEmpty
                          ? 'Location not set'
                          : item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB6C2D8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.instructor.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: Color(0xFFB6C2D8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.instructor,
                      style: const TextStyle(
                        color: Color(0xFFB6C2D8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaHeader extends StatelessWidget {
  const _AgendaHeader({required this.weekday, required this.count});

  final int weekday;
  final int count;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday == weekday;
    return Row(
      children: [
        Text(
          today ? "Today's classes" : weekdays[weekday - 1],
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9ECF6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'TAP TO EDIT',
          style: TextStyle(
            color: _muted,
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleClass item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _classColors[item.colorIndex % _classColors.length];
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE9EC),
          borderRadius: BorderRadius.circular(19),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 13),
                SizedBox(
                  width: 71,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatMinutes(item.startMinutes),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatMinutes(item.endMinutes),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.location.isEmpty ? item.instructor : item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (item.reminderMinutes > 0) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 16,
                    color: color.withValues(alpha: 0.8),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB8C0CE),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.weekday, required this.onAdd});

  final int weekday;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 27),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: _brand,
              size: 24,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'A free day!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'No classes on ${weekdays[weekday - 1]}. Add one whenever you like.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add a class'),
          ),
        ],
      ),
    );
  }
}

class _FooterTip extends StatelessWidget {
  const _FooterTip({required this.classCount});

  final int classCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: _brand, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              classCount == 0
                  ? 'Add your classes and we’ll help you stay on track.'
                  : 'Tip: tap a class to update its time, room, or reminder.',
              style: const TextStyle(
                color: Color(0xFF596581),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              'We couldn’t load your schedule',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class ScheduleForm extends StatefulWidget {
  const ScheduleForm({super.key, this.initialClass});

  final ScheduleClass? initialClass;

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _instructorController;
  late final TextEditingController _locationController;
  late int _weekday;
  late int _startMinutes;
  late int _endMinutes;
  late int _reminderMinutes;
  late int _colorIndex;

  bool get _isEditing => widget.initialClass != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialClass;
    _nameController = TextEditingController(text: item?.name ?? '');
    _instructorController = TextEditingController(text: item?.instructor ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _weekday = item?.weekday ?? DateTime.now().weekday;
    _startMinutes = item?.startMinutes ?? 9 * 60;
    _endMinutes = item?.endMinutes ?? 10 * 60;
    _reminderMinutes = item?.reminderMinutes ?? 10;
    _colorIndex =
        item?.colorIndex ?? DateTime.now().weekday % _classColors.length;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _chooseTime({required bool start}) async {
    final minutes = start ? _startMinutes : _endMinutes;
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _brand),
        ),
        child: child!,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final selectedMinutes = result.hour * 60 + result.minute;
      if (start) {
        _startMinutes = selectedMinutes;
        if (_endMinutes <= _startMinutes) {
          _endMinutes = (_startMinutes + 60) % (24 * 60);
        }
      } else {
        _endMinutes = selectedMinutes;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_endMinutes <= _startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The end time must be later than the start time.'),
        ),
      );
      return;
    }
    final existing = widget.initialClass;
    Navigator.of(context).pop(
      ScheduleClass(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        instructor: _instructorController.text.trim(),
        location: _locationController.text.trim(),
        weekday: _weekday,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        reminderMinutes: _reminderMinutes,
        colorIndex: _colorIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE1EA),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit class' : 'Add a class',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: _canvas,
                      foregroundColor: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'CLASS NAME', required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Introduction to Biology',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a class name'
                            : null,
                      ),
                      const SizedBox(height: 17),
                      _FieldLabel(label: 'INSTRUCTOR'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _instructorController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Add instructor name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 17),
                      _FieldLabel(label: 'ROOM OR LOCATION'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Science Hall · 204',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel(
                        label: 'DAY OF THE WEEK',
                        required: true,
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final selected = _weekday == day;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index == 6 ? 0 : 5,
                              ),
                              child: InkWell(
                                onTap: () => setState(() => _weekday = day),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected ? _brand : _canvas,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      const [
                                        'M',
                                        'T',
                                        'W',
                                        'T',
                                        'F',
                                        'S',
                                        'S',
                                      ][index],
                                      style: TextStyle(
                                        color: selected ? Colors.white : _ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel(label: 'CLASS TIME', required: true),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeButton(
                              title: 'STARTS',
                              value: formatMinutes(_startMinutes),
                              onTap: () => _chooseTime(start: true),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: _muted,
                              size: 17,
                            ),
                          ),
                          Expanded(
                            child: _TimeButton(
                              title: 'ENDS',
                              value: formatMinutes(_endMinutes),
                              onTap: () => _chooseTime(start: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel(label: 'REMIND ME BEFORE'),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _canvas,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _reminderMinutes,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(15),
                            icon: const Icon(Icons.expand_more_rounded),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('No reminder'),
                              ),
                              DropdownMenuItem(
                                value: 5,
                                child: Text('5 minutes before'),
                              ),
                              DropdownMenuItem(
                                value: 10,
                                child: Text('10 minutes before'),
                              ),
                              DropdownMenuItem(
                                value: 15,
                                child: Text('15 minutes before'),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Text('30 minutes before'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _reminderMinutes = value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel(label: 'COLOR'),
                      const SizedBox(height: 9),
                      Row(
                        children: List.generate(_classColors.length, (index) {
                          final selected = _colorIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () => setState(() => _colorIndex = index),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: _classColors[index],
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(
                                          color: _classColors[index].withValues(
                                            alpha: 0.25,
                                          ),
                                          width: 5,
                                          strokeAlign:
                                              BorderSide.strokeAlignOutside,
                                        )
                                      : null,
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 53,
                child: FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    _isEditing ? Icons.check_rounded : Icons.add_rounded,
                  ),
                  label: Text(
                    _isEditing ? 'Save changes' : 'Add to schedule',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (required)
          const Text(
            '  *',
            style: TextStyle(color: _brand, fontWeight: FontWeight.w800),
          ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _canvas,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _muted,
                fontSize: 9,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 15, color: _brand),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
