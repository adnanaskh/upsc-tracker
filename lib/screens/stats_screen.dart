import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabController;
  List<Map<String, dynamic>> _mcqTests = [];
  List<Map<String, dynamic>> _answerWriting = [];
  Map<String, int> _subjectMinutes = {};
  List<Map<String, dynamic>> _weeklyData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _mcqTests = await _db.getMcqTests();
    _answerWriting = await _db.getAnswerWriting();
    _subjectMinutes = await _db.getSubjectWiseMinutes();
    _weeklyData = await _db.getWeeklyStudyData();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subjects'),
            Tab(text: 'Tests'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(provider),
                _buildSubjectsTab(),
                _buildTestsTab(provider),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(label: 'Current Streak', value: '${provider.currentStreak}d', icon: Icons.local_fire_department, color: AppTheme.gold, subtitle: 'Keep going!'),
              StatCard(label: 'Best Streak', value: '${provider.longestStreak}d', icon: Icons.emoji_events, color: AppTheme.secondary),
              StatCard(label: 'Days Studied', value: '${provider.totalDaysStudied}', icon: Icons.calendar_today, color: AppTheme.primary),
              StatCard(label: 'MCQ Tests', value: '${_mcqTests.length}', icon: Icons.quiz, color: const Color(0xFFFF6B6B)),
            ],
          ),
          const SizedBox(height: 24),

          // Weekly chart
          const Text('Weekly Study (Last 7 Days)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildWeeklyChart(),
          const SizedBox(height: 24),

          // Phase progress
          const Text('Phase Progress', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildPhaseProgress(provider),
          const SizedBox(height: 24),

          // Answer writing count
          GlassCard(
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.draw, color: AppTheme.primary)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_answerWriting.length} Answers Written', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      const Text('Target: 1/day from Sep 2027', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Build last 7 days data
    final days = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      days[DateFormat('yyyy-MM-dd').format(d)] = 0;
    }
    for (final row in _weeklyData) {
      final date = row['date'] as String;
      if (days.containsKey(date)) {
        days[date] = (row['total'] as num).toInt();
      }
    }

    final entries = days.entries.toList();
    final maxY = (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 30).toDouble();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY > 0 ? maxY : 120,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem('${rod.toY.toInt()}m', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700));
                },
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= entries.length) return const Text('');
                    final date = DateTime.parse(entries[idx].key);
                    return Text(DateFormat('E').format(date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11));
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()}m', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.surfaceVariant, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(entries.length, (index) {
              final value = entries[index].value.toDouble();
              final isToday = index == entries.length - 1;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: isToday ? AppTheme.primary : AppTheme.primary.withOpacity(0.5),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseProgress(AppProvider provider) {
    final phases = [
      {'label': 'Phase 1 — Foundation', 'period': 'Mar–Dec 2026', 'color': const Color(0xFF6C63FF)},
      {'label': 'Phase 2 — Depth', 'period': 'Jan–Dec 2027', 'color': const Color(0xFF00D4AA)},
      {'label': 'Phase 3 — Integration', 'period': 'Jan–Sep 2028', 'color': const Color(0xFFFF9800)},
      {'label': 'Phase 4 — Final Push', 'period': 'Oct 2028–2029', 'color': const Color(0xFFFF6B6B)},
    ];

    return GlassCard(
      child: Column(
        children: phases.asMap().entries.map((entry) {
          final idx = entry.key;
          final phase = entry.value;
          final isCurrentPhase = provider.currentPhase == idx + 1;
          final isDone = provider.currentPhase > idx + 1;
          final color = phase['color'] as Color;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone ? color : isCurrentPhase ? color.withOpacity(0.2) : AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: isCurrentPhase ? Border.all(color: color, width: 2) : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${idx + 1}', style: TextStyle(color: isCurrentPhase ? color : AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phase['label'] as String, style: TextStyle(color: isCurrentPhase ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: isCurrentPhase ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
                      Text(phase['period'] as String, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                if (isCurrentPhase)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('NOW', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectsTab() {
    if (_subjectMinutes.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'No Data Yet',
        subtitle: 'Log study sessions to see subject-wise statistics',
      );
    }

    final sorted = _subjectMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0, (sum, e) => sum + e.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie chart
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Time Distribution', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: sorted.map((e) {
                        final color = AppTheme.subjectColors[e.key] ?? AppTheme.primary;
                        final percent = total > 0 ? (e.value / total * 100) : 0.0;
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: color,
                          radius: 70,
                          title: percent > 5 ? '${percent.toInt()}%' : '',
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        );
                      }).toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subject bars
          const Text('Subject-wise Hours', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...sorted.map((e) {
            final color = AppTheme.subjectColors[e.key] ?? AppTheme.primary;
            final hours = e.value / 60;
            final percent = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubjectBadge(subject: e.key, small: true),
                        const Spacer(),
                        Text('${hours.toStringAsFixed(1)}h (${(percent * 100).toInt()}%)',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: AppTheme.surfaceVariant,
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTestsTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Log MCQ test button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showLogMcqDialog(context, provider),
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: const Text('Log MCQ Test'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showLogAnswerDialog(context, provider),
                  icon: const Icon(Icons.draw_outlined, size: 18),
                  label: const Text('Log Answer'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.card),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_mcqTests.isNotEmpty) ...[
            const Text('MCQ Test History', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._mcqTests.take(20).map((test) {
              final total = (test['total_questions'] as int?) ?? 0;
              final correct = (test['correct'] as int?) ?? 0;
              final percent = total > 0 ? correct / total : 0.0;
              final color = percent >= 0.7 ? AppTheme.success : percent >= 0.5 ? AppTheme.warning : AppTheme.error;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ProgressRing(progress: percent, size: 50, color: color, strokeWidth: 5,
                        child: Text('${(percent * 100).toInt()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$correct/$total correct', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                            if ((test['subject'] as String?)?.isNotEmpty == true)
                              SubjectBadge(subject: test['subject'] as String, small: true),
                          ],
                        ),
                      ),
                      Text(test['date'] as String? ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              );
            }),
          ],

          if (_answerWriting.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Answer Writing Log', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._answerWriting.take(15).map((aw) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_document, color: AppTheme.primary, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aw['topic'] as String? ?? 'Answer', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                          Row(children: [
                            if ((aw['subject'] as String?)?.isNotEmpty == true) SubjectBadge(subject: aw['subject'] as String, small: true),
                            if ((aw['paper'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(width: 6),
                              Text(aw['paper'] as String, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if ((aw['self_score'] as int? ?? 0) > 0)
                          Text('${aw['self_score']}/10', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
                        Text(aw['date'] as String? ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            )),
          ],

          if (_mcqTests.isEmpty && _answerWriting.isEmpty)
            const EmptyState(
              icon: Icons.quiz,
              title: 'No Tests Logged',
              subtitle: 'Log your MCQ tests and answer writing to track performance',
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showLogMcqDialog(BuildContext context, AppProvider provider) {
    String subject = 'History';
    int total = 20, correct = 0;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log MCQ Test', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: subject, dropdownColor: AppTheme.card,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                items: ['History', 'Geography', 'Polity', 'Economy', 'Sociology', 'Ethics', 'Art & Culture', 'Science & Tech', 'Environment', 'Current Affairs', 'CSAT', 'All Subjects']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setModal(() => subject = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(children: [
                  const Text('Total Qs', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Row(children: [
                    IconButton(onPressed: () { if (total > 1) setModal(() => total--); }, icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary, size: 20)),
                    Text('$total', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    IconButton(onPressed: () => setModal(() => total++), icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 20)),
                  ]),
                ])),
                Expanded(child: Column(children: [
                  const Text('Correct', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  Row(children: [
                    IconButton(onPressed: () { if (correct > 0) setModal(() => correct--); }, icon: const Icon(Icons.remove_circle_outline, color: AppTheme.success, size: 20)),
                    Text('$correct', style: const TextStyle(color: AppTheme.success, fontSize: 20, fontWeight: FontWeight.w800)),
                    IconButton(onPressed: () { if (correct < total) setModal(() => correct++); }, icon: const Icon(Icons.add_circle_outline, color: AppTheme.success, size: 20)),
                  ]),
                ])),
              ]),
              const SizedBox(height: 8),
              Center(child: Text('Score: ${total > 0 ? (correct / total * 100).toInt() : 0}%  (${correct}/${total})', style: const TextStyle(color: AppTheme.textSecondary))),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Notes (weak areas...)')),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  await provider.logMcqTest(subject: subject, total: total, correct: correct, notes: notesCtrl.text);
                  _loadData();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogAnswerDialog(BuildContext context, AppProvider provider) {
    final topicCtrl = TextEditingController();
    String subject = 'Sociology';
    String paper = 'Paper 1';
    int wordCount = 200, selfScore = 7;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Answer Writing', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: topicCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Topic / Question...')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: subject, dropdownColor: AppTheme.card, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  items: ['Sociology', 'History', 'Geography', 'Polity', 'Economy', 'Ethics', 'Essay']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModal(() => subject = v!),
                )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(
                  value: paper, dropdownColor: AppTheme.card, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Paper', labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  items: ['Paper 1', 'Paper 2', 'GS1', 'GS2', 'GS3', 'GS4', 'Essay']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModal(() => paper = v!),
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Text('Self score: ', style: TextStyle(color: AppTheme.textSecondary)),
                Expanded(child: Slider(
                  value: selfScore.toDouble(), min: 1, max: 10, divisions: 9,
                  activeColor: AppTheme.primary, inactiveColor: AppTheme.surfaceVariant,
                  label: '$selfScore/10',
                  onChanged: (v) => setModal(() => selfScore = v.toInt()),
                )),
                Text('$selfScore/10', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  await provider.logAnswerWriting(
                    topic: topicCtrl.text.trim().isEmpty ? 'Answer' : topicCtrl.text.trim(),
                    subject: subject, paper: paper,
                    wordCount: wordCount, selfScore: selfScore,
                    notes: notesCtrl.text,
                  );
                  _loadData();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
