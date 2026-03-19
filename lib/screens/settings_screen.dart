import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseService();
  final _notif = NotificationService();
  bool _morningAlarm = true;
  int _alarmHour = 5;
  int _alarmMinute = 30;
  bool _eveningReminder = true;
  bool _sundayReminder = true;
  bool _monthlyReview = true;
  bool _loading = true;
  int _dailyTarget = 120;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final alarm = await _db.getSetting('morning_alarm_enabled');
    final alarmTime = await _db.getSetting('morning_alarm_time');
    final target = await _db.getSetting('daily_target_minutes');

    setState(() {
      _morningAlarm = alarm != 'false';
      if (alarmTime != null) {
        final parts = alarmTime.split(':');
        _alarmHour = int.tryParse(parts[0]) ?? 5;
        _alarmMinute = int.tryParse(parts[1]) ?? 30;
      }
      _dailyTarget = int.tryParse(target ?? '120') ?? 120;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  GlassCard(
                    gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.2), AppTheme.primaryDark.withOpacity(0.05)]),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: Text('AA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Adnan Ahmad', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                              const Text('B.Tech CSE 2027', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Text('🎯 IAS 2029', style: TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phase settings
                  const Text('CURRENT PHASE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Phase', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(4, (i) {
                            final phase = i + 1;
                            final selected = provider.currentPhase == phase;
                            const colors = [Color(0xFF6C63FF), Color(0xFF00D4AA), Color(0xFFFF9800), Color(0xFFFF6B6B)];
                            final labels = ['Foundation', 'Depth', 'Integration', 'Final Push'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => provider.setCurrentPhase(phase),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? colors[i].withOpacity(0.2) : AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: selected ? colors[i] : Colors.transparent, width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('P$phase', style: TextStyle(color: selected ? colors[i] : AppTheme.textMuted, fontWeight: FontWeight.w800, fontSize: 15)),
                                      Text(labels[i], style: TextStyle(color: selected ? colors[i] : AppTheme.textMuted, fontSize: 9), textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Daily target
                  const Text('STUDY TARGET', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Daily Target', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${_dailyTarget}m (${_dailyTarget ~/ 60}h ${_dailyTarget % 60}m)', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _dailyTarget.toDouble(),
                          min: 60,
                          max: 480,
                          divisions: 28,
                          activeColor: AppTheme.primary,
                          inactiveColor: AppTheme.surfaceVariant,
                          label: '${_dailyTarget}m',
                          onChanged: (v) => setState(() => _dailyTarget = v.toInt()),
                          onChangeEnd: (v) => provider.setDailyTarget(v.toInt()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1h', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const Text('2h (Weekday)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const Text('8h', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifications
                  const Text('REMINDERS & NOTIFICATIONS', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        // Morning alarm
                        Row(
                          children: [
                            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.alarm, color: AppTheme.gold, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Morning Study Alarm', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: () => _pickAlarmTime(context, provider),
                                    child: Text(
                                      '${_alarmHour.toString().padLeft(2, '0')}:${_alarmMinute.toString().padLeft(2, '0')} AM — tap to change',
                                      style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _morningAlarm,
                              onChanged: (v) {
                                setState(() => _morningAlarm = v);
                                provider.setMorningAlarm(v, hour: _alarmHour, minute: _alarmMinute);
                              },
                              activeColor: AppTheme.primary,
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.surfaceVariant, height: 24),

                        // Evening reminder
                        _notifRow(
                          icon: Icons.edit_note,
                          iconColor: AppTheme.secondary,
                          title: 'Evening Session Log Reminder',
                          subtitle: '9:00 PM — daily',
                          value: _eveningReminder,
                          onChanged: (v) {
                            setState(() => _eveningReminder = v);
                            if (v) _notif.scheduleEveningReminder();
                          },
                        ),
                        const Divider(color: AppTheme.surfaceVariant, height: 24),

                        // Sunday reminder
                        _notifRow(
                          icon: Icons.quiz_outlined,
                          iconColor: AppTheme.primary,
                          title: 'Sunday Self-Test & Planning',
                          subtitle: '7:00 PM & 8:00 PM every Sunday',
                          value: _sundayReminder,
                          onChanged: (v) {
                            setState(() => _sundayReminder = v);
                            if (v) _notif.scheduleSundayReminders();
                          },
                        ),
                        const Divider(color: AppTheme.surfaceVariant, height: 24),

                        // Monthly review
                        _notifRow(
                          icon: Icons.bar_chart,
                          iconColor: AppTheme.warning,
                          title: 'Monthly Review Reminder',
                          subtitle: 'Last day of each month',
                          value: _monthlyReview,
                          onChanged: (v) {
                            setState(() => _monthlyReview = v);
                            if (v) _notif.scheduleMonthlyReview();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App info
                  const Text('APP INFO', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        _infoRow('Preparation Start', '1 April 2026'),
                        _infoRow('Target Exam', 'UPSC CSE 2029'),
                        _infoRow('Optional Subject', 'Sociology'),
                        _infoRow('Total Books', '40 books'),
                        _infoRow('Total Phases', '4 phases'),
                        _infoRow('App Version', 'v1.0.0'),
                        _infoRow('Storage', 'Fully Offline (SQLite)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Motivation quote
                  GlassCard(
                    gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.1), Colors.transparent]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('💬 Planner Wisdom', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                        SizedBox(height: 8),
                        Text(
                          '"Consistency beats intensity — 2 hours daily for 3 years beats 14 hours for 3 months. Start today. Order your Phase 1 books. Begin reading next Monday at 5:30 am. Inshallah, IAS 2029."',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _notifRow({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Row(
      children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _pickAlarmTime(BuildContext context, AppProvider provider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _alarmHour, minute: _alarmMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.card)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _alarmHour = picked.hour; _alarmMinute = picked.minute; });
      provider.setMorningAlarm(_morningAlarm, hour: picked.hour, minute: picked.minute);
    }
  }
}
