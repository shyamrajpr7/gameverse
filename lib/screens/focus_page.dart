import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/gamification_service.dart';

const Color _cardBg = Color(0xFF1E293B);
const Color _violet = Color(0xFF8B5CF6);
const Color _emerald = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _rose = Color(0xFFF43F5E);
const Color _cyan = Color(0xFF06B6D4);
const Color _amber = Color(0xFFF59E0B);
const Color _slateText = Color(0xFF94A3B8);
const Color _whiteText = Color(0xFFF1F5F9);

class FocusSession {
  final String taskTitle;
  final String? taskId;
  final int durationSeconds;
  final DateTime completedAt;

  FocusSession({
    required this.taskTitle,
    this.taskId,
    required this.durationSeconds,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'taskTitle': taskTitle,
        'taskId': taskId,
        'durationSeconds': durationSeconds,
        'completedAt': completedAt.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        taskTitle: json['taskTitle'] as String? ?? 'Focus Session',
        taskId: json['taskId'] as String?,
        durationSeconds: json['durationSeconds'] as int? ?? 1500,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final h = m ~/ 60;
    final remainingM = m % 60;
    if (h > 0) return '${h}h ${remainingM}m';
    return '${remainingM}m';
  }
}

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  Timer? _timer;
  int _remainingSeconds = 1500;
  int _focusDuration = 1500;
  int _breakDuration = 300;
  bool _isRunning = false;
  bool _isBreak = false;
  int _focusStreak = 0;
  bool _strictMode = false;
  bool _treeDead = false;

  List<FocusSession> _sessions = [];
  List<Map<String, dynamic>> _availableTasks = [];
  String? _selectedTaskTitle;
  String? _selectedTaskId;

  final List<Map<String, dynamic>> _focusPresets = [
    {'label': '15', 'seconds': 900},
    {'label': '25', 'seconds': 1500},
    {'label': '30', 'seconds': 1800},
    {'label': '45', 'seconds': 2700},
  ];

  final List<Map<String, dynamic>> _breakPresets = [
    {'label': '3', 'seconds': 180},
    {'label': '5', 'seconds': 300},
    {'label': '10', 'seconds': 600},
    {'label': '15', 'seconds': 900},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      if (_strictMode && !_isBreak) {
        _killTree();
      } else {
        _pauseTimer();
      }
    }
  }

  // ─── Data persistence ───

  Future<void> _loadData() async {
    await Future.wait([_loadSessions(), _loadTasks()]);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('tasks');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data) as List<dynamic>;
      setState(() {
        _availableTasks = jsonList
            .where((j) => j['isCompleted'] == false)
            .map((j) => Map<String, dynamic>.from(j as Map))
            .toList();
      });
    }
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('focus_sessions');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data) as List<dynamic>;
      setState(() {
        _sessions = jsonList
            .map((j) => FocusSession.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      });
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString('focus_sessions', data);
  }

  // ─── Timer logic ───

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onTimerComplete();
      }
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    if (_strictMode && !_isBreak && !_treeDead) {
      _killTree();
      return;
    }
    setState(() => _isRunning = false);
  }

  void _killTree() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _treeDead = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mood_bad_rounded, color: _rose, size: 20),
            SizedBox(width: 8),
            Text('Strict mode: tree withered. No XP awarded.',
                style: TextStyle(color: _whiteText, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: _cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  String get _phaseLabel => _isBreak ? 'Break' : 'Focus';

  Color get _phaseColor => _isBreak ? _emerald : _violet;

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _treeDead = false;
      _remainingSeconds = _focusDuration;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() => _isRunning = false);

    if (_isBreak) {
      _showBreakCompleteDialog();
    } else {
      if (_treeDead) {
        setState(() => _treeDead = false);
        _resetTimer();
        return;
      }
      final session = FocusSession(
        taskTitle: _selectedTaskTitle ?? 'Focus Session',
        taskId: _selectedTaskId,
        durationSeconds: _focusDuration,
        completedAt: DateTime.now(),
      );
      _sessions.insert(0, session);
      _saveSessions();
      _focusStreak++;

      final xpGain = _focusDuration ~/ 60;
      GamificationService().addXP(xpGain);
      GamificationService().incrementFocusSessions();

      NotificationService().show(
        id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
        title: '🎉 Focus Complete!',
        body: _selectedTaskTitle != null
            ? 'Great work on "$_selectedTaskTitle"'
            : 'Great focus session!',
      );
      _showSessionCompleteDialog();
    }
  }

  void _showSessionCompleteDialog() {
    final xpGained = _focusDuration ~/ 60;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Focus Complete!',
            style: TextStyle(color: _whiteText, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedTaskTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('"$_selectedTaskTitle"',
                    style: const TextStyle(color: _violet, fontWeight: FontWeight.w600)),
              ),
            Text('${_formatTime(_focusDuration)} focused',
                style: const TextStyle(color: _slateText, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, size: 16, color: _amber),
                  const SizedBox(width: 6),
                  Text('+$xpGained XP',
                      style: const TextStyle(
                          color: _amber, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            if (_focusStreak > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 18, color: _amber),
                    const SizedBox(width: 4),
                    Text('$_focusStreak session streak!',
                        style: const TextStyle(color: _amber, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startBreak();
            },
            child: Text('Break ${_formatTime(_breakDuration)}',
                style: const TextStyle(color: _emerald, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
              _startTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Next Focus'),
          ),
        ],
      ),
    );
  }

  void _startBreak() {
    setState(() {
      _isBreak = true;
      _remainingSeconds = _breakDuration;
      _isRunning = false;
    });
    _startTimer();
  }

  void _showBreakCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('☕ Break Over!',
            style: TextStyle(color: _whiteText, fontWeight: FontWeight.w800)),
        content: const Text('Ready to focus again?',
            style: TextStyle(color: _slateText)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
            },
            child: const Text('Done for Now',
                style: TextStyle(color: _slateText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetTimer();
              _startTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Start Focus'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _isBreak ? _breakDuration : _focusDuration;
    if (total == 0) return 0.0;
    return 1.0 - (_remainingSeconds / total);
  }

  int get _totalTodayMinutes {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return _sessions
        .where((s) => s.completedAt.isAfter(start))
        .fold(0, (sum, s) => sum + s.durationSeconds) ~/
        60;
  }

  int get _todaySessionCount =>
      _sessions.where((s) {
        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day);
        return s.completedAt.isAfter(start);
      }).length;

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildTimerCircle(),
            const SizedBox(height: 20),
            _buildDurationChips(),
            const SizedBox(height: 12),
            _buildStrictModeToggle(),
            const SizedBox(height: 24),
            _buildTaskSelector(),
            const SizedBox(height: 24),
            _buildControls(),
            const SizedBox(height: 32),
            _buildTodayStats(),
            const SizedBox(height: 20),
            _buildRecentSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _violet.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.timer_rounded, color: _violet, size: 22),
        ),
        const SizedBox(width: 12),
        const Text(
          'Focus Timer',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _whiteText,
          ),
        ),
        const Spacer(),
        if (_focusStreak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 16, color: _amber),
                const SizedBox(width: 4),
                Text('$_focusStreak',
                    style: const TextStyle(
                        color: _amber,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimerCircle() {
    final treeStage = _getTreeStage();
    final treeIcon = treeStage['icon'] as IconData;
    final treeSize = treeStage['size'] as double;
    final treeColor = treeStage['color'] as Color;
    final treeLabel = treeStage['label'] as String;

    return Center(
      child: SizedBox(
        width: 220,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _treeDead ? 0.0 : _progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: _slateText.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          _treeDead ? _rose : _phaseColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(treeIcon, size: treeSize, color: treeColor),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(_remainingSeconds),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _whiteText,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _treeDead ? 'Withered' : treeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _treeDead ? _rose : _slateText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _phaseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _treeDead ? 'Failed' : _phaseLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _treeDead ? _rose : _phaseColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrictModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _strictMode
              ? _rose.withValues(alpha: 0.3)
              : _slateText.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _strictMode ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 16,
            color: _strictMode ? _rose : _slateText.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strict Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _strictMode ? _whiteText : _slateText,
                  ),
                ),
                Text(
                  _strictMode
                      ? 'Pausing kills the tree & forfeits XP'
                      : 'Stay focused or lose progress',
                  style: TextStyle(
                    fontSize: 10,
                    color: _slateText.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _strictMode,
            onChanged: (val) {
              if (_isRunning) return;
              setState(() => _strictMode = val);
            },
            activeThumbColor: _rose,
            activeTrackColor: _rose.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTreeStage() {
    if (_treeDead) {
      return {
        'icon': Icons.mood_bad_rounded,
        'size': 36.0,
        'color': _rose.withValues(alpha: 0.6),
        'label': 'Tree withered',
      };
    }
    if (!_isRunning && !_isBreak && _remainingSeconds == _focusDuration) {
      return {
        'icon': Icons.eco,
        'size': 30.0,
        'color': _slateText.withValues(alpha: 0.4),
        'label': 'Plant a seed',
      };
    }
    if (_isBreak) {
      return {
        'icon': Icons.nightlight_round,
        'size': 34.0,
        'color': _emerald.withValues(alpha: 0.6),
        'label': 'Resting...',
      };
    }
    final p = _progress;
    if (p < 0.33) {
      return {
        'icon': Icons.eco,
        'size': 32.0,
        'color': _emerald.withValues(alpha: 0.7),
        'label': 'Sprouting...',
      };
    } else if (p < 0.66) {
      return {
        'icon': Icons.forest,
        'size': 38.0,
        'color': _emerald,
        'label': 'Growing...',
      };
    } else if (p < 1.0) {
      return {
        'icon': Icons.forest,
        'size': 44.0,
        'color': _emerald.withValues(alpha: 0.9),
        'label': 'Almost there!',
      };
    }
    return {
      'icon': Icons.auto_awesome,
      'size': 44.0,
      'color': _amber,
      'label': 'Full Bloom!',
    };
  }

  Widget _buildDurationChips() {
    final presets = _isBreak ? _breakPresets : _focusPresets;
    final current = _isBreak ? _breakDuration : _focusDuration;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: presets.map((p) {
            final seconds = p['seconds'] as int;
            final selected = seconds == current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: _isRunning ? null : () => _setDuration(seconds),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _phaseColor.withValues(alpha: 0.15)
                        : _slateText.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? _phaseColor.withValues(alpha: 0.5)
                          : _slateText.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '${p['label']}m',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? _phaseColor : _slateText,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        if (!_isBreak)
          GestureDetector(
            onTap: () {
              setState(() {
                _isBreak = !_isBreak;
                _remainingSeconds = _breakDuration;
                _isRunning = false;
              });
              _timer?.cancel();
            },
            child: Text(
              'Break mode (${_formatTime(_breakDuration)})',
              style: TextStyle(
                fontSize: 11,
                color: _emerald.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _setDuration(int seconds) {
    if (_isBreak) {
      setState(() {
        _breakDuration = seconds;
        _remainingSeconds = seconds;
      });
    } else {
      setState(() {
        _focusDuration = seconds;
        _remainingSeconds = seconds;
      });
    }
  }

  Widget _buildTaskSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slateText.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTaskTitle,
          isExpanded: true,
          dropdownColor: _cardBg,
          hint: Row(
            children: [
              Icon(Icons.playlist_add_check_rounded,
                  size: 16, color: _slateText.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              const Text('Select a task to focus on',
                  style: TextStyle(color: _slateText, fontSize: 14)),
            ],
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: _slateText.withValues(alpha: 0.6)),
          style: const TextStyle(color: _whiteText, fontSize: 14),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('No task selected',
                  style: TextStyle(color: _slateText)),
            ),
            ..._availableTasks.map((task) {
              final title = task['title'] as String? ?? '';
              return DropdownMenuItem(
                value: title,
                child: Row(
                  children: [
                    if (task['isHighPriority'] == true)
                      Icon(Icons.local_fire_department_rounded,
                          size: 14, color: _red.withValues(alpha: 0.7)),
                    if (task['isHighPriority'] == true)
                      const SizedBox(width: 6),
                    Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              _selectedTaskTitle = val;
              _selectedTaskId = val != null
                  ? _availableTasks
                      .firstWhere((t) => t['title'] == val)['id'] as String?
                  : null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: _isRunning ? 'Pause' : 'Start',
          color: _violet,
          onTap: () {
            if (_isRunning) {
              _pauseTimer();
            } else {
              _startTimer();
            }
          },
        ),
        const SizedBox(width: 16),
        _ControlButton(
          icon: Icons.restart_alt_rounded,
          label: 'Reset',
          color: _slateText,
          onTap: _resetTimer,
        ),
      ],
    );
  }

  Widget _buildTodayStats() {
    final hours = _totalTodayMinutes ~/ 60;
    final mins = _totalTodayMinutes % 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _violet.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.schedule_rounded,
              value: '${hours}h ${mins}m',
              label: 'Today Focused',
              color: _violet,
            ),
          ),
          Container(width: 1, height: 36, color: _slateText.withValues(alpha: 0.1)),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_outline_rounded,
              value: '$_todaySessionCount',
              label: 'Sessions',
              color: _emerald,
            ),
          ),
          Container(width: 1, height: 36, color: _slateText.withValues(alpha: 0.1)),
          Expanded(
            child: _StatItem(
              icon: Icons.storage_rounded,
              value: '${_sessions.length}',
              label: 'Total',
              color: _cyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    final recent = _sessions.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recent Sessions',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _whiteText)),
            const Spacer(),
            if (recent.isNotEmpty)
              Text('${_sessions.length} total',
                  style: const TextStyle(
                      fontSize: 12, color: _slateText)),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _slateText.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Icon(Icons.timer_off_rounded,
                    size: 28, color: _slateText.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text('No sessions yet today',
                    style: TextStyle(
                        fontSize: 13, color: _slateText.withValues(alpha: 0.5))),
                const SizedBox(height: 4),
                Text('Start your first focus session above',
                    style: TextStyle(
                        fontSize: 12, color: _slateText.withValues(alpha: 0.3))),
              ],
            ),
          )
        else
          ...recent.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < recent.length - 1 ? 6 : 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _slateText.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _violet.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_rounded,
                          size: 16, color: _violet),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.taskTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _whiteText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(s.completedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: _slateText.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.formattedDuration,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = date.difference(today).inDays;

    if (diff == 0) {
      return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff == -1) {
      return 'Yesterday, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Reusable widgets ───

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _whiteText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _slateText.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
