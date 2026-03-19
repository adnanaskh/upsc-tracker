import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _activeGoals = [];
  List<Map<String, dynamic>> _completedGoals = [];
  bool _loading = true;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    _activeGoals = await _db.getGoals(completed: false);
    _completedGoals = await _db.getGoals(completed: true);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Goals & Targets'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
            child: Text(_showCompleted ? 'Active' : 'Completed (${_completedGoals.length})',
                style: const TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, provider),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: AppTheme.surface,
                  child: Row(
                    children: [
                      _summaryPill('${_activeGoals.length}', 'Active', AppTheme.primary),
                      const SizedBox(width: 10),
                      _summaryPill('${_completedGoals.length}', 'Completed', AppTheme.success),
                      const Spacer(),
                      PhaseBadge(phase: provider.currentPhase),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadGoals,
                    color: AppTheme.primary,
                    child: (_showCompleted ? _completedGoals : _activeGoals).isEmpty
                        ? EmptyState(
                            icon: Icons.flag,
                            title: _showCompleted ? 'No Completed Goals Yet' : 'No Active Goals',
                            subtitle: _showCompleted ? 'Keep working — goals will appear here when done!' : 'Set your first study goal',
                            actionLabel: _showCompleted ? null : 'Add Goal',
                            onAction: _showCompleted ? null : () => _showAddGoalDialog(context, provider),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: (_showCompleted ? _completedGoals : _activeGoals).length,
                            itemBuilder: (context, index) {
                              final goal = (_showCompleted ? _completedGoals : _activeGoals)[index];
                              return _buildGoalCard(goal, context, provider);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text('$value $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, BuildContext context, AppProvider provider) {
    final completed = (goal['completed'] as int) == 1;
    final priority = goal['priority'] as String? ?? 'medium';
    final targetDate = goal['target_date'] as String?;
    final subject = goal['subject'] as String?;

    Color priorityColor;
    switch (priority) {
      case 'high': priorityColor = AppTheme.error; break;
      case 'medium': priorityColor = AppTheme.warning; break;
      default: priorityColor = AppTheme.textMuted;
    }

    bool isOverdue = false;
    if (!completed && targetDate != null) {
      try {
        final date = DateTime.parse(targetDate);
        isOverdue = date.isBefore(DateTime.now());
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _toggleGoal(goal, provider),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: completed ? AppTheme.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: completed ? AppTheme.success : AppTheme.textMuted, width: 2),
                ),
                child: completed ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal['title'] as String,
                    style: TextStyle(
                      color: completed ? AppTheme.textMuted : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if ((goal['description'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(goal['description'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      PhaseBadge(phase: (goal['phase'] as int?) ?? 1),
                      if (subject?.isNotEmpty == true) SubjectBadge(subject: subject!, small: true),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: priorityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('${priority[0].toUpperCase()}${priority.substring(1)} Priority', style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (targetDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isOverdue ? Icons.warning_amber : Icons.calendar_today,
                          size: 12,
                          color: isOverdue ? AppTheme.error : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${_formatDate(targetDate)}${isOverdue ? ' (Overdue!)' : ''}',
                          style: TextStyle(color: isOverdue ? AppTheme.error : AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _toggleGoal(Map<String, dynamic> goal, AppProvider provider) async {
    final done = (goal['completed'] as int) == 1;
    await provider.updateGoal(
      goal['id'] as int,
      {'completed': done ? 0 : 1, 'completion_date': done ? null : provider.todayDate},
    );
    _loadGoals();
  }

  void _showAddGoalDialog(BuildContext context, AppProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String subject = 'Sociology';
    String priority = 'medium';
    int phase = provider.currentPhase;
    DateTime? targetDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Goal', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Goal title *')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, style: const TextStyle(color: AppTheme.textPrimary), maxLines: 2, decoration: const InputDecoration(hintText: 'Description (optional)')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: subject, dropdownColor: AppTheme.card, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    items: ['History', 'Geography', 'Polity', 'Economy', 'Sociology', 'Ethics', 'Art & Culture', 'Science & Tech', 'Environment', 'Current Affairs', 'General']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setModal(() => subject = v!),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<int>(
                    value: phase, dropdownColor: AppTheme.card, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Phase', labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    items: [1, 2, 3, 4].map((p) => DropdownMenuItem(value: p, child: Text('Phase $p'))).toList(),
                    onChanged: (v) => setModal(() => phase = v!),
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Text('Priority: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ...['low', 'medium', 'high'].map((p) {
                    final selected = priority == p;
                    Color c = p == 'high' ? AppTheme.error : p == 'medium' ? AppTheme.warning : AppTheme.textMuted;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () => setModal(() => priority = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? c.withOpacity(0.2) : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? c : Colors.transparent),
                          ),
                          child: Text(p[0].toUpperCase() + p.substring(1), style: TextStyle(color: selected ? c : AppTheme.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                        ),
                      ),
                    );
                  }),
                ]),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.card)),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModal(() => targetDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          targetDate != null ? DateFormat('d MMM yyyy').format(targetDate!) : 'Set target date (optional)',
                          style: TextStyle(color: targetDate != null ? AppTheme.textPrimary : AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    await _db.insertGoal({
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'subject': subject,
                      'phase': phase,
                      'priority': priority,
                      'target_date': targetDate?.toIso8601String().substring(0, 10),
                      'completed': 0,
                    });
                    _loadGoals();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Goal'),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
