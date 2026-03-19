import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'log_session_screen.dart';
import 'planner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final greeting = _getGreeting(now.hour);
        final dayName = DateFormat('EEEE, d MMMM').format(now);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: AppTheme.primary,
            backgroundColor: AppTheme.card,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  expandedHeight: 0,
                  title: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('IAS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('UPSC CSE 2029', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          Text(provider.userName, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.currentStreak}',
                            style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Greeting
                      Text(
                        '$greeting, ${provider.userName.split(' ').first}!',
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      Text(dayName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 20),

                      // Streak + Phase banner
                      _buildHeroBanner(context, provider),
                      const SizedBox(height: 20),

                      // Today's progress
                      _buildTodayProgress(context, provider),
                      const SizedBox(height: 20),

                      // Quick log button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LogSessionScreen())).then((_) => provider.refresh()),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Log Study Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Today's tasks
                      _buildTodayTasks(context, provider),
                      const SizedBox(height: 20),

                      // Daily habits
                      _buildHabitsSection(context, provider),
                      const SizedBox(height: 20),

                      // Quick stats row
                      _buildQuickStats(context, provider),
                      const SizedBox(height: 20),

                      // Days until exam
                      _buildCountdown(context, provider),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeroBanner(BuildContext context, AppProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primary.withOpacity(0.3),
          AppTheme.primaryDark.withOpacity(0.1),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhaseBadge(phase: provider.currentPhase),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${provider.currentStreak} days',
                          style: const TextStyle(color: AppTheme.gold, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const Text('Current Streak', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Best: ${provider.longestStreak} days  •  Total: ${provider.totalDaysStudied} days studied',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ProgressRing(
                progress: provider.todayProgress,
                size: 72,
                color: AppTheme.secondary,
                strokeWidth: 7,
                child: Text(
                  '${(provider.todayProgress * 100).toInt()}%',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${provider.todayMinutes}/${provider.dailyTarget}m',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgress(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Today's Schedule"),
        if (provider.todayTasks.isEmpty)
          GlassCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen())).then((_) => provider.refresh()),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No tasks planned yet', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      Text('Tap to open daily planner', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 14),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTodayTasks(BuildContext context, AppProvider provider) {
    if (provider.todayTasks.isEmpty) return const SizedBox.shrink();
    final completed = provider.todayTasks.where((t) => (t['completed'] as int) == 1).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Today's Tasks ($completed/${provider.todayTasks.length})",
          actionLabel: 'Planner',
          onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen())).then((_) => provider.refresh()),
        ),
        ...provider.todayTasks.map((task) {
          final done = (task['completed'] as int) == 1;
          final subject = task['subject'] as String? ?? '';
          final color = AppTheme.subjectColors[subject] ?? AppTheme.primary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => provider.togglePlannerTask(task['id'] as int, !done),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: done ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: done ? color : AppTheme.textMuted, width: 2),
                    ),
                    child: done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] as String,
                          style: TextStyle(
                            color: done ? AppTheme.textMuted : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (subject.isNotEmpty)
                          Text(subject, style: TextStyle(color: color, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('${task['duration_minutes']}m', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHabitsSection(BuildContext context, AppProvider provider) {
    final habits = provider.todayHabits ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Daily Habits'),
        GlassCard(
          child: Column(
            children: [
              _habitRow(provider, habits, 'morning_study', 'Morning Study 5:30 AM', Icons.wb_sunny_outlined, AppTheme.gold),
              const SizedBox(height: 8),
              _habitRow(provider, habits, 'chapter_notes', 'Chapter Notes (5 bullets)', Icons.edit_note, AppTheme.secondary),
              const SizedBox(height: 8),
              _habitRow(provider, habits, 'mcq_practice', 'MCQ Practice', Icons.quiz_outlined, AppTheme.primary),
              const SizedBox(height: 8),
              _habitRow(provider, habits, 'answer_writing', 'Answer Writing', Icons.draw_outlined, const Color(0xFFFF6B6B)),
              const SizedBox(height: 8),
              _habitRow(provider, habits, 'newspaper_read', 'Newspaper / Current Affairs', Icons.newspaper_outlined, const Color(0xFF4ECDC4)),
              const SizedBox(height: 8),
              _habitRow(provider, habits, 'ignou_reading', 'IGNOU Unit Reading', Icons.school_outlined, const Color(0xFFE056FD)),
              const SizedBox(height: 8),
              _habitRow(provider, habits, 'physical_health', 'Walk 30 min + 7 hrs Sleep', Icons.directions_walk, AppTheme.success),
            ],
          ),
        ),
      ],
    );
  }

  Widget _habitRow(AppProvider provider, Map<String, dynamic> habits, String key, String label, IconData icon, Color color) {
    final checked = (habits[key] as int? ?? 0) == 1;
    return HabitCheckbox(
      label: label,
      checked: checked,
      onToggle: () => provider.toggleHabit(key),
      icon: icon,
      color: color,
    );
  }

  Widget _buildQuickStats(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Stats'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              label: 'Current Streak',
              value: '${provider.currentStreak}d',
              icon: Icons.local_fire_department,
              color: AppTheme.gold,
              subtitle: 'Best: ${provider.longestStreak}d',
            ),
            StatCard(
              label: 'Days Studied',
              value: '${provider.totalDaysStudied}',
              icon: Icons.calendar_today,
              color: AppTheme.secondary,
              subtitle: 'Since Apr 2026',
            ),
            StatCard(
              label: 'Today',
              value: '${provider.todayMinutes}m',
              icon: Icons.timer,
              color: AppTheme.primary,
              subtitle: 'Target: ${provider.dailyTarget}m',
            ),
            StatCard(
              label: 'Days to Exam',
              value: '${provider.daysUntilExam}',
              icon: Icons.flag,
              color: AppTheme.error,
              subtitle: 'UPSC Prelims ~Jun 2029',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdown(BuildContext context, AppProvider provider) {
    final days = provider.daysUntilExam;
    final weeks = days ~/ 7;
    final months = days ~/ 30;
    return GlassCard(
      gradient: LinearGradient(
        colors: [AppTheme.error.withOpacity(0.2), AppTheme.accent.withOpacity(0.05)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🎯', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Countdown to UPSC CSE 2029', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _countdownBox('$days', 'DAYS'),
              _countdownBox('$weeks', 'WEEKS'),
              _countdownBox('$months', 'MONTHS'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '"Consistency beats intensity. 2 hours daily for 3 years beats 14 hours for 3 months."',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _countdownBox(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppTheme.error, fontSize: 28, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ],
    );
  }
}
