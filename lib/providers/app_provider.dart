import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();

  // State
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalDaysStudied = 0;
  int _currentPhase = 1;
  Map<String, dynamic>? _todayHabits;
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, int> _subjectMinutes = {};
  bool _isLoading = false;
  String _userName = 'Adnan Ahmad';
  int _todayMinutes = 0;
  int _dailyTarget = 120;

  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalDaysStudied => _totalDaysStudied;
  int get currentPhase => _currentPhase;
  Map<String, dynamic>? get todayHabits => _todayHabits;
  List<Map<String, dynamic>> get todayTasks => _todayTasks;
  List<Map<String, dynamic>> get weeklyData => _weeklyData;
  Map<String, int> get subjectMinutes => _subjectMinutes;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  int get todayMinutes => _todayMinutes;
  int get dailyTarget => _dailyTarget;

  String get todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _notif.initialize();
    } catch (e) {
      debugPrint('Notification init error: $e');
    }

    try {
      await _loadAllData();
    } catch (e) {
      debugPrint('Data load error: $e');
    }

    try {
      await _setupDefaultNotifications();
    } catch (e) {
      debugPrint('Notification setup error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllData() async {
    _currentStreak = await _db.getCurrentStreak();
    _longestStreak = await _db.getLongestStreak();
    _totalDaysStudied = await _db.getTotalDaysStudied();

    final phaseStr = await _db.getSetting('current_phase');
    _currentPhase = int.tryParse(phaseStr ?? '1') ?? 1;

    final nameStr = await _db.getSetting('user_name');
    _userName = nameStr ?? 'Adnan Ahmad';

    final targetStr = await _db.getSetting('daily_target_minutes');
    _dailyTarget = int.tryParse(targetStr ?? '120') ?? 120;

    _todayHabits = await _db.getDailyHabits(todayDate);
    _todayTasks = await _db.getPlannerTasks(todayDate);
    _weeklyData = await _db.getWeeklyStudyData();
    _subjectMinutes = await _db.getSubjectWiseMinutes();

    _todayMinutes =
        await _db.getTotalStudyMinutes(fromDate: todayDate, toDate: todayDate);
  }

  Future<void> _setupDefaultNotifications() async {
    final morningEnabled = await _db.getSetting('morning_alarm_enabled');
    if (morningEnabled == 'true') {
      await _notif.scheduleMorningAlarm(5, 30);
    }
    await _notif.scheduleEveningReminder();
    await _notif.scheduleSundayReminders();
    await _notif.scheduleMonthlyReview();
  }

  Future<void> refresh() async {
    await _loadAllData();
    notifyListeners();
  }

  // Log study session
  Future<void> logStudySession({
    required String subject,
    required int durationMinutes,
    String? topic,
    String? book,
    int? pagesCovered,
    String? notes,
  }) async {
    await _db.insertStudySession({
      'date': todayDate,
      'subject': subject,
      'topic': topic ?? '',
      'book': book ?? '',
      'duration_minutes': durationMinutes,
      'pages_covered': pagesCovered ?? 0,
      'notes': notes ?? '',
      'phase': _currentPhase,
    });

    // Update habits total
    final habits = _todayHabits ?? {'date': todayDate, 'total_minutes': 0};
    final newTotal = ((habits['total_minutes'] as int?) ?? 0) + durationMinutes;
    await _db.upsertDailyHabits(
        {...habits, 'date': todayDate, 'total_minutes': newTotal});

    await _loadAllData();

    // Check milestones
    if (_currentStreak == 7)
      await _notif
          .showMilestone('7-day streak! One week of consistency. Keep going!');
    if (_currentStreak == 30)
      await _notif.showMilestone(
          '30-day streak! One month of dedication. Inshallah IAS 2029!');
    if (_currentStreak == 100)
      await _notif.showMilestone('100-day streak! You\'re unstoppable, Adnan!');

    notifyListeners();
  }

  // Toggle habit
  Future<void> toggleHabit(String habitKey) async {
    final habits =
        Map<String, dynamic>.from(_todayHabits ?? {'date': todayDate});
    habits['date'] = todayDate;
    habits[habitKey] = ((habits[habitKey] as int?) ?? 0) == 1 ? 0 : 1;
    await _db.upsertDailyHabits(habits);
    _todayHabits = habits;
    notifyListeners();
  }

  // Add planner task
  Future<void> addPlannerTask({
    required String title,
    required String date,
    String? subject,
    int durationMinutes = 60,
    String taskType = 'study',
  }) async {
    final existingTasks = await _db.getPlannerTasks(date);
    await _db.insertPlannerTask({
      'date': date,
      'title': title,
      'subject': subject ?? '',
      'duration_minutes': durationMinutes,
      'completed': 0,
      'order_index': existingTasks.length,
      'task_type': taskType,
    });
    _todayTasks = await _db.getPlannerTasks(todayDate);
    notifyListeners();
  }

  Future<void> togglePlannerTask(int id, bool completed) async {
    await _db.updatePlannerTask(id, {'completed': completed ? 1 : 0});
    _todayTasks = await _db.getPlannerTasks(todayDate);
    notifyListeners();
  }

  Future<void> deletePlannerTask(int id) async {
    await _db.deletePlannerTask(id);
    _todayTasks = await _db.getPlannerTasks(todayDate);
    notifyListeners();
  }

  // Update book progress
  Future<void> updateBookProgress(int bookId,
      {int? chaptersCompleted, int? pagesRead, String? status}) async {
    final updates = <String, dynamic>{};
    if (chaptersCompleted != null)
      updates['chapters_completed'] = chaptersCompleted;
    if (pagesRead != null) updates['pages_read'] = pagesRead;
    if (status != null) {
      updates['status'] = status;
      if (status == 'in_progress') updates['start_date'] = todayDate;
      if (status == 'completed') updates['completion_date'] = todayDate;
    }
    await _db.updateBook(bookId, updates);
    notifyListeners();
  }

  // Log MCQ test
  Future<void> logMcqTest(
      {required String subject,
      required int total,
      required int correct,
      String? notes}) async {
    await _db.insertMcqTest({
      'date': todayDate,
      'subject': subject,
      'total_questions': total,
      'correct': correct,
      'incorrect': total - correct,
      'notes': notes ?? '',
      'phase': _currentPhase,
    });
    notifyListeners();
  }

  // Log answer writing
  Future<void> logAnswerWriting(
      {required String topic,
      required String subject,
      String? paper,
      int? wordCount,
      int? selfScore,
      String? notes}) async {
    await _db.insertAnswerWriting({
      'date': todayDate,
      'topic': topic,
      'subject': subject,
      'paper': paper ?? '',
      'word_count': wordCount ?? 0,
      'self_score': selfScore ?? 0,
      'notes': notes ?? '',
    });
    // Update answer writing habit
    final habits =
        Map<String, dynamic>.from(_todayHabits ?? {'date': todayDate});
    habits['date'] = todayDate;
    habits['answer_writing'] = 1;
    await _db.upsertDailyHabits(habits);
    _todayHabits = habits;
    notifyListeners();
  }

  // Update thinker mastery
  Future<void> updateGoal(int id, Map<String, dynamic> updates) async {
    await _db.updateGoal(id, updates);
    notifyListeners();
  }

  Future<void> updateThinkerMastery(
      int id, int mastery, bool answerWritten) async {
    await _db.updateThinker(id, {
      'mastery_level': mastery,
      'answer_written': answerWritten ? 1 : 0,
      'last_revised': todayDate,
    });
    notifyListeners();
  }

  // Settings
  Future<void> setMorningAlarm(bool enabled,
      {int hour = 5, int minute = 30}) async {
    await _db.setSetting('morning_alarm_enabled', enabled.toString());
    await _db.setSetting('morning_alarm_time',
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    if (enabled) {
      await _notif.scheduleMorningAlarm(hour, minute);
    } else {
      await _notif.cancelMorningAlarm();
    }
    notifyListeners();
  }

  Future<void> setCurrentPhase(int phase) async {
    _currentPhase = phase;
    await _db.setSetting('current_phase', phase.toString());
    notifyListeners();
  }

  Future<void> setDailyTarget(int minutes) async {
    _dailyTarget = minutes;
    await _db.setSetting('daily_target_minutes', minutes.toString());
    notifyListeners();
  }

  // Get phase label
  String get currentPhaseLabel {
    switch (_currentPhase) {
      case 1:
        return 'Foundation';
      case 2:
        return 'Depth';
      case 3:
        return 'Integration';
      case 4:
        return 'Final Push';
      default:
        return 'Foundation';
    }
  }

  // Phase date ranges
  String get currentPhaseDates {
    switch (_currentPhase) {
      case 1:
        return 'Mar–Dec 2026';
      case 2:
        return 'Jan–Dec 2027';
      case 3:
        return 'Jan–Sep 2028';
      case 4:
        return 'Oct 2028–2029';
      default:
        return 'Mar–Dec 2026';
    }
  }

  // Days until exam
  int get daysUntilExam {
    final examDate = DateTime(2029, 6, 1); // approximate Prelims date
    return examDate.difference(DateTime.now()).inDays;
  }

  double get todayProgress =>
      _dailyTarget > 0 ? (_todayMinutes / _dailyTarget).clamp(0.0, 1.0) : 0.0;
}
