import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _db = DatabaseService();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _tasks = [];
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final date = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final tasks = await _db.getPlannerTasks(date);
    setState(() => _tasks = tasks);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Daily Planner'),
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.view_list : Icons.calendar_month),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
              _loadTasks();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, provider),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: Column(
        children: [
          // Calendar (collapsible)
          if (_showCalendar)
            Container(
              color: AppTheme.surface,
              child: TableCalendar(
                firstDay: DateTime(2026, 4, 1),
                lastDay: DateTime(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: AppTheme.textPrimary),
                  weekendTextStyle: TextStyle(color: AppTheme.textSecondary),
                  selectedDecoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppTheme.primaryDark, shape: BoxShape.circle),
                  outsideDaysVisible: false,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                  leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  weekendStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                onDaySelected: (selected, focused) {
                  setState(() { _selectedDay = selected; _focusedDay = focused; });
                  _loadTasks();
                },
              ),
            ),

          // Date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppTheme.surface,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(_selectedDay),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      DateFormat('d MMMM yyyy').format(_selectedDay),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('TODAY', style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(width: 8),
                // Progress
                if (_tasks.isNotEmpty)
                  Text(
                    '${_tasks.where((t) => (t['completed'] as int) == 1).length}/${_tasks.length}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child: _tasks.isEmpty
                ? EmptyState(
                    icon: Icons.event_note,
                    title: 'No Tasks Planned',
                    subtitle: 'Add study tasks for ${DateFormat('d MMM').format(_selectedDay)}',
                    actionLabel: 'Add Task',
                    onAction: () => _showAddTaskDialog(context, provider),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final task = _tasks.removeAt(oldIndex);
                      _tasks.insert(newIndex, task);
                      setState(() {});
                      for (int i = 0; i < _tasks.length; i++) {
                        await _db.updatePlannerTask(_tasks[i]['id'] as int, {'order_index': i});
                      }
                    },
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final done = (task['completed'] as int) == 1;
                      final subject = task['subject'] as String? ?? '';
                      final color = AppTheme.subjectColors[subject] ?? AppTheme.primary;
                      return Dismissible(
                        key: Key('task_${task['id']}'),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: AppTheme.error),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          await _db.deletePlannerTask(task['id'] as int);
                          if (isToday) provider.deletePlannerTask(task['id'] as int);
                          _loadTasks();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () async {
                              await _db.updatePlannerTask(task['id'] as int, {'completed': done ? 0 : 1});
                              if (isToday) provider.togglePlannerTask(task['id'] as int, !done);
                              _loadTasks();
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: done ? color : Colors.transparent,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(color: done ? color : AppTheme.textMuted, width: 2),
                                  ),
                                  child: done ? const Icon(Icons.check, color: Colors.white, size: 15) : null,
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          decoration: done ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (subject.isNotEmpty) SubjectBadge(subject: subject, small: true),
                                          if (subject.isNotEmpty) const SizedBox(width: 8),
                                          Icon(Icons.timer_outlined, color: AppTheme.textMuted, size: 12),
                                          const SizedBox(width: 3),
                                          Text('${task['duration_minutes']}m', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.drag_handle, color: AppTheme.textMuted, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppProvider provider) {
    final titleController = TextEditingController();
    String selectedSubject = 'History';
    int duration = 60;
    String taskType = 'study';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Task', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(hintText: 'Task title...'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                dropdownColor: AppTheme.card,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                items: ['History', 'Geography', 'Polity', 'Economy', 'Sociology', 'Ethics', 'Art & Culture', 'Science & Tech', 'Environment', 'Current Affairs', 'CSAT', 'Essay']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setModalState(() => selectedSubject = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Duration: ', style: TextStyle(color: AppTheme.textSecondary)),
                  Wrap(
                    spacing: 6,
                    children: [30, 60, 90, 120].map((d) => ChoiceChip(
                      label: Text('${d}m'),
                      selected: duration == d,
                      onSelected: (_) => setModalState(() => duration = d),
                      selectedColor: AppTheme.primary.withOpacity(0.3),
                      labelStyle: TextStyle(color: duration == d ? AppTheme.primary : AppTheme.textSecondary, fontSize: 12),
                    )).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final date = DateFormat('yyyy-MM-dd').format(_selectedDay);
                    await provider.addPlannerTask(
                      title: titleController.text.trim(),
                      date: date,
                      subject: selectedSubject,
                      durationMinutes: duration,
                    );
                    _loadTasks();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
