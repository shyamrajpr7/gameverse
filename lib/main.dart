import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'dart:math';

class Task {
  final String id;
  String title;
  bool isCompleted;
  bool isHighPriority;
  DateTime? reminderTime;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isHighPriority = false,
    this.reminderTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'isHighPriority': isHighPriority,
        'reminderTime': reminderTime?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        isHighPriority: json['isHighPriority'] as bool? ?? false,
        reminderTime: json['reminderTime'] != null
            ? DateTime.parse(json['reminderTime'] as String)
            : null,
      );

  int get notificationId => id.hashCode & 0x7FFFFFFF;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macOsSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOsSettings,
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for your daily tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    final macOsDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOsDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}

const Color _bgCanvas = Color(0xFF0F172A);
const Color _cardBg = Color(0xFF1E293B);
const Color _red = Color(0xFFEF4444);
const Color _violet = Color(0xFF8B5CF6);
const Color _cyan = Color(0xFF06B6D4);
const Color _emerald = Color(0xFF10B981);
const Color _slateText = Color(0xFF94A3B8);
const Color _whiteText = Color(0xFFF1F5F9);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const TaskMasterApp());
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bgCanvas,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: _violet,
          surface: _cardBg,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Task> _tasks = [];
  final _inputController = TextEditingController();
  bool _pendingHighPriority = false;
  TimeOfDay? _pendingReminder;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  List<Task> get _highPriority =>
      _tasks.where((t) => !t.isCompleted && t.isHighPriority).toList();
  List<Task> get _scheduled =>
      _tasks.where((t) => !t.isCompleted && !t.isHighPriority && t.reminderTime != null).toList();
  List<Task> get _general =>
      _tasks.where((t) => !t.isCompleted && !t.isHighPriority && t.reminderTime == null).toList();
  List<Task> get _done => _tasks.where((t) => t.isCompleted).toList();

  double get _progress {
    if (_tasks.isEmpty) return 0.0;
    return _done.length / _tasks.length;
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('tasks');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data) as List<dynamic>;
      setState(() {
        _tasks.clear();
        for (final json in jsonList) {
          _tasks.add(Task.fromJson(json as Map<String, dynamic>));
        }
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', data);
  }

  void _addTask(String title, bool isHighPriority, TimeOfDay? reminder) {
    final task = Task(
      id: '${DateTime.now().toIso8601String()}_${Random().nextInt(99999)}',
      title: title,
      isHighPriority: isHighPriority,
      reminderTime: reminder != null
          ? DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              reminder.hour,
              reminder.minute,
            )
          : null,
    );
    setState(() => _tasks.insert(0, task));
    _saveTasks();
    if (task.reminderTime != null) {
      _scheduleReminder(task);
    }
  }

  void _toggleTask(Task task) {
    setState(() => task.isCompleted = !task.isCompleted);
    _saveTasks();
    if (task.isCompleted && task.reminderTime != null) {
      NotificationService().cancel(task.notificationId);
    }
    if (task.isCompleted == false && task.reminderTime != null) {
      _scheduleReminder(task);
    }
  }

  void _deleteTask(Task task) {
    setState(() => _tasks.remove(task));
    _saveTasks();
    if (task.reminderTime != null) {
      NotificationService().cancel(task.notificationId);
    }
  }

  Future<void> _scheduleReminder(Task task) async {
    final now = DateTime.now();
    var reminderDate = DateTime(
      now.year,
      now.month,
      now.day,
      task.reminderTime!.hour,
      task.reminderTime!.minute,
    );
    if (reminderDate.isBefore(now)) {
      reminderDate = reminderDate.add(const Duration(days: 1));
    }
    await NotificationService().schedule(
      id: task.notificationId,
      title: 'Task Reminder',
      body: 'Don\'t forget: ${task.title}',
      scheduledDate: reminderDate,
    );
  }

  void _openAddSheet() {
    _inputController.clear();
    _pendingHighPriority = false;
    _pendingReminder = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        controller: _inputController,
        isHighPriority: _pendingHighPriority,
        reminder: _pendingReminder,
        onChanged: (highPriority, reminder) {
          _pendingHighPriority = highPriority;
          _pendingReminder = reminder;
        },
        onSubmit: () {
          final text = _inputController.text.trim();
          if (text.isNotEmpty) {
            _addTask(text, _pendingHighPriority, _pendingReminder);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatRow(),
              const SizedBox(height: 24),
              if (_highPriority.isNotEmpty) ...[
                _buildSectionHeader('🔥 High Priority', _highPriority.length, _red),
                const SizedBox(height: 8),
                ..._highPriority.map((t) => _TaskCard(
                  task: t,
                  accentColor: _red,
                  onToggle: () => _toggleTask(t),
                  onDelete: () => _deleteTask(t),
                )),
                const SizedBox(height: 20),
              ],
              if (_scheduled.isNotEmpty) ...[
                _buildSectionHeader('📅 Scheduled', _scheduled.length, _violet),
                const SizedBox(height: 8),
                ..._scheduled.map((t) => _TaskCard(
                  task: t,
                  accentColor: _violet,
                  onToggle: () => _toggleTask(t),
                  onDelete: () => _deleteTask(t),
                )),
                const SizedBox(height: 20),
              ],
              if (_general.isNotEmpty) ...[
                _buildSectionHeader('📋 Tasks', _general.length, _cyan),
                const SizedBox(height: 8),
                ..._general.map((t) => _TaskCard(
                  task: t,
                  accentColor: _cyan,
                  onToggle: () => _toggleTask(t),
                  onDelete: () => _deleteTask(t),
                )),
                const SizedBox(height: 20),
              ],
              if (_done.isNotEmpty) ...[
                _buildSectionHeader('✅ Done', _done.length, _emerald),
                const SizedBox(height: 8),
                ..._done.map((t) => _TaskCard(
                  task: t,
                  accentColor: _emerald,
                  onToggle: () => _toggleTask(t),
                  onDelete: () => _deleteTask(t),
                )),
                const SizedBox(height: 20),
              ],
              if (_tasks.isEmpty) _buildEmptyState(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, Shyamraj! 👋',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _whiteText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
          style: const TextStyle(
            fontSize: 14,
            color: _slateText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow() {
    final pending = _tasks.length - _done.length;
    final completedToday = _done.length;
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _StatCard(
              gradientColors: [_violet.withValues(alpha: 0.3), _violet.withValues(alpha: 0.05)],
              borderColor: _violet.withValues(alpha: 0.4),
              child: Row(
                children: [
                  _ProgressRing(progress: _progress),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(fontSize: 12, color: _slateText, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _whiteText,
                        ),
                      ),
                      Text(
                        '${_done.length} of ${_tasks.length} done',
                        style: const TextStyle(fontSize: 12, color: _slateText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _StatCard(
                    gradientColors: [_cyan.withValues(alpha: 0.25), _cyan.withValues(alpha: 0.05)],
                    borderColor: _cyan.withValues(alpha: 0.35),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: _cyan),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$pending',
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800, color: _whiteText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Pending', style: TextStyle(fontSize: 12, color: _slateText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _StatCard(
                    gradientColors: [_emerald.withValues(alpha: 0.25), _emerald.withValues(alpha: 0.05)],
                    borderColor: _emerald.withValues(alpha: 0.35),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: _emerald),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completedToday',
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800, color: _whiteText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Done', style: TextStyle(fontSize: 12, color: _slateText)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _whiteText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_violet.withValues(alpha: 0.2), _violet.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _violet.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.checklist_rounded, size: 32, color: _violet.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your day is clear.',
              style: TextStyle(fontSize: 18, color: _slateText),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to add your first task',
              style: TextStyle(fontSize: 13, color: _slateText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Color borderColor;
  final Widget child;

  const _StatCard({
    required this.gradientColors,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  const _ProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
            backgroundColor: _slateText.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(_violet),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _whiteText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final Task task;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.accentColor,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: _isDeleting ? 0.0 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        transform: _isDeleting
            ? (Matrix4.identity()..setTranslationRaw(100.0, 0.0, 0.0))
            : Matrix4.identity(),
        margin: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border(
                left: BorderSide(color: widget.accentColor, width: 3),
                bottom: BorderSide(color: widget.accentColor.withValues(alpha: 0.15)),
                right: BorderSide(color: widget.accentColor.withValues(alpha: 0.08)),
                top: BorderSide(color: widget.accentColor.withValues(alpha: 0.08)),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.task.isCompleted ? _emerald : Colors.transparent,
                      border: Border.all(
                        color: widget.task.isCompleted ? _emerald : widget.accentColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: widget.task.isCompleted
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: widget.task.isCompleted ? FontWeight.w400 : FontWeight.w600,
                          color: widget.task.isCompleted ? _slateText : _whiteText,
                          decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: _slateText,
                        ),
                        child: Text(widget.task.title),
                      ),
                      if (widget.task.reminderTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.alarm_rounded, size: 12, color: _violet.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.task.reminderTime!.hour.toString().padLeft(2, '0')}:${widget.task.reminderTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 12, color: _violet.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.task.isHighPriority && !widget.task.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('High', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _red)),
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() => _isDeleting = true);
                    Future.delayed(const Duration(milliseconds: 350), widget.onDelete);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded, size: 16, color: _slateText.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
      ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final TextEditingController controller;
  final bool isHighPriority;
  final TimeOfDay? reminder;
  final Function(bool, TimeOfDay?) onChanged;
  final VoidCallback onSubmit;

  const _AddTaskSheet({
    required this.controller,
    required this.isHighPriority,
    required this.reminder,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  late bool _highPriority;
  TimeOfDay? _reminder;

  @override
  void initState() {
    super.initState();
    _highPriority = widget.isHighPriority;
    _reminder = widget.reminder;
  }

  void _notify() => widget.onChanged(_highPriority, _reminder);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _slateText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'New Task',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _whiteText,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: widget.controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => widget.onSubmit(),
              style: const TextStyle(color: _whiteText, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                hintStyle: TextStyle(color: _slateText.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _violet, width: 2),
                ),
                filled: true,
                fillColor: _bgCanvas,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _TagChip(
                  label: 'High Priority',
                  icon: Icons.local_fire_department_rounded,
                  selected: _highPriority,
                  selectedColor: _red,
                  onTap: () {
                    setState(() => _highPriority = !_highPriority);
                    _notify();
                  },
                ),
                const SizedBox(width: 10),
                _TagChip(
                  label: _reminder != null ? _reminder!.format(context) : 'Set Reminder',
                  icon: Icons.alarm_rounded,
                  selected: _reminder != null,
                  selectedColor: _violet,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _reminder ?? TimeOfDay.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(primary: _violet, surface: _cardBg),
                        ),
                        child: child!,
                      ),
                    );
                    if (time != null) {
                      setState(() => _reminder = time);
                      _notify();
                    }
                  },
                ),
                if (_reminder != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _reminder = null);
                      _notify();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.close, size: 16, color: _slateText),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_violet, Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: widget.onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.15) : _bgCanvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? selectedColor.withValues(alpha: 0.5) : _slateText.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? selectedColor : _slateText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? selectedColor : _slateText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
