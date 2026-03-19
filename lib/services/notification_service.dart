import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'morning_study',
        'Morning Study Alarm',
        description: 'Daily 5:30 AM study reminder',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'reminders',
        'Study Reminders',
        description: 'Subject rotation and habit reminders',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'streak',
        'Streak Alerts',
        description: 'Streak protection and milestone alerts',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'weekly',
        'Weekly Reminders',
        description: 'Sunday self-test and planning reminders',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'monthly',
        'Monthly Review',
        description: 'Monthly progress review alerts',
        importance: Importance.defaultImportance,
      ),
    ];

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTap(NotificationResponse response) {}

  // Schedule daily 5:30 AM alarm
  Future<void> scheduleMorningAlarm(int hour, int minute) async {
    await _notifications.cancel(1);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notifications.zonedSchedule(
      1,
      '🌅 Morning Study Time — 5:30 AM',
      'Adnan, your IAS journey continues now. Open your book. 2029 is waiting.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'morning_study',
          'Morning Study Alarm',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            'This is your most protected study time. Phone in another room. Read one chapter. Build the streak.',
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel morning alarm
  Future<void> cancelMorningAlarm() async {
    await _notifications.cancel(1);
  }

  // Subject rotation reminder
  Future<void> scheduleSubjectReminder(String subject, int hour, int minute) async {
    await _notifications.cancel(2);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notifications.zonedSchedule(
      2,
      '📚 Study Session: $subject',
      'Time to study $subject. Stay consistent — 2 hours daily beats 14 hours occasionally.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Study Reminders',
            importance: Importance.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Evening habit reminder
  Future<void> scheduleEveningReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notifications.zonedSchedule(
      3,
      '📝 Log Today\'s Study Session',
      'Track your progress! Log your chapters, minutes, and check habits.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Study Reminders',
            importance: Importance.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Sunday reminders
  Future<void> scheduleSundayReminders() async {
    // Sunday 8 PM — weekly self-test
    await _notifications.cancel(10);
    final now = tz.TZDateTime.now(tz.local);
    var nextSunday = now;
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    final sundayEvening = tz.TZDateTime(
        tz.local, nextSunday.year, nextSunday.month, nextSunday.day, 20, 0);
    await _notifications.zonedSchedule(
      10,
      '🧪 Sunday Self-Test Time!',
      '20 MCQs from this week\'s topics. Gaps found now = gaps fixed before exam.',
      sundayEvening,
      const NotificationDetails(
        android: AndroidNotificationDetails('weekly', 'Weekly Reminders',
            importance: Importance.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _notifications.cancel(11);
    final sundayPlanning = tz.TZDateTime(
        tz.local, nextSunday.year, nextSunday.month, nextSunday.day, 19, 0);
    await _notifications.zonedSchedule(
      11,
      '📅 Plan Next Week\'s Targets',
      'Set exact chapter targets for Mon–Sat. Without targets, weeks disappear.',
      sundayPlanning,
      const NotificationDetails(
        android: AndroidNotificationDetails('weekly', 'Weekly Reminders',
            importance: Importance.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Monthly review
  Future<void> scheduleMonthlyReview() async {
    await _notifications.cancel(20);
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final scheduledTime = tz.TZDateTime(
        tz.local, lastDay.year, lastDay.month, lastDay.day, 20, 0);
    if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notifications.zonedSchedule(
        20,
        '📊 Monthly Review Time!',
        'Check targets vs actual progress. Adjust your plan. Stay on track for IAS 2029.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails('monthly', 'Monthly Review',
              importance: Importance.defaultImportance),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Streak protection
  Future<void> showStreakAtRisk(int currentStreak) async {
    await _notifications.show(
      30,
      '🔥 Streak at Risk! ($currentStreak days)',
      'You haven\'t logged today\'s study yet. Don\'t break the chain!',
      const NotificationDetails(
        android: AndroidNotificationDetails('streak', 'Streak Alerts',
            importance: Importance.high),
      ),
    );
  }

  // Milestone notification
  Future<void> showMilestone(String message) async {
    await _notifications.show(
      31,
      '🏆 Milestone Achieved!',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails('streak', 'Streak Alerts',
            importance: Importance.high),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
