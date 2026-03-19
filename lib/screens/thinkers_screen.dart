import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ThinkersScreen extends StatefulWidget {
  const ThinkersScreen({super.key});
  @override
  State<ThinkersScreen> createState() => _ThinkersScreenState();
}

class _ThinkersScreenState extends State<ThinkersScreen> with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabController;
  List<Map<String, dynamic>> _thinkers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_loadThinkers);
    _loadThinkers();
  }

  Future<void> _loadThinkers() async {
    setState(() => _loading = true);
    final paper = _tabController.index == 1 ? 'Paper 1' : _tabController.index == 2 ? 'Paper 2' : null;
    final thinkers = await _db.getThinkers(paper: paper);
    setState(() { _thinkers = thinkers; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final mastered = _thinkers.where((t) => (t['mastery_level'] as int? ?? 0) >= 3).length;
    final answered = _thinkers.where((t) => (t['answer_written'] as int? ?? 0) == 1).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Sociology Thinkers'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Paper 1 (Theory)'),
            Tab(text: 'Paper 2 (India)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _progressPill('$mastered/${_thinkers.length}', 'Mastered', AppTheme.success),
                const SizedBox(width: 10),
                _progressPill('$answered/${_thinkers.length}', 'Answers Written', AppTheme.primary),
                const Spacer(),
                Text('${_thinkers.length} thinkers', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _thinkers.isEmpty
                    ? const EmptyState(icon: Icons.person, title: 'No Thinkers', subtitle: 'Thinkers will appear here')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _thinkers.length,
                        itemBuilder: (context, index) => _buildThinkerCard(_thinkers[index], context),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _progressPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text('$value $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildThinkerCard(Map<String, dynamic> thinker, BuildContext context) {
    final priority = thinker['priority'] as String? ?? 'medium';
    final mastery = thinker['mastery_level'] as int? ?? 0;
    final answered = (thinker['answer_written'] as int? ?? 0) == 1;
    final paper = thinker['paper'] as String? ?? '';

    Color priorityColor;
    String priorityLabel;
    switch (priority) {
      case 'very_high': priorityColor = AppTheme.error; priorityLabel = 'Very High'; break;
      case 'high': priorityColor = AppTheme.warning; priorityLabel = 'High'; break;
      default: priorityColor = AppTheme.textMuted; priorityLabel = 'Medium';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => _showThinkerDetail(context, thinker),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      thinker['name'].toString().split(' ').last[0],
                      style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(thinker['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: priorityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(priorityLabel, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                            child: Text(paper, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < mastery ? Icons.star : Icons.star_outline,
                        color: i < mastery ? AppTheme.gold : AppTheme.textMuted,
                        size: 14,
                      )),
                    ),
                    const SizedBox(height: 4),
                    if (answered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Ans ✓', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
            if ((thinker['key_concepts'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(thinker['key_concepts'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if ((thinker['ignou_ref'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.school_outlined, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text('IGNOU: ${thinker['ignou_ref']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  void _showThinkerDetail(BuildContext context, Map<String, dynamic> thinker) {
    final provider = context.read<AppProvider>();
    int mastery = thinker['mastery_level'] as int? ?? 0;
    bool answered = (thinker['answer_written'] as int? ?? 0) == 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(thinker['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${thinker['paper']} · ${thinker['priority']?.toString().replaceAll('_', ' ') ?? ''} priority',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              if ((thinker['key_concepts'] as String?)?.isNotEmpty == true) ...[
                const Text('Key Concepts', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(thinker['key_concepts'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                const SizedBox(height: 16),
              ],
              if ((thinker['ignou_ref'] as String?)?.isNotEmpty == true) ...[
                const Text('IGNOU Reference', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(thinker['ignou_ref'] as String, style: const TextStyle(color: AppTheme.primary, fontSize: 14)),
                const SizedBox(height: 16),
              ],
              const Text('Mastery Level', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setModal(() => mastery = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(i < mastery ? Icons.star : Icons.star_outline, color: i < mastery ? AppTheme.gold : AppTheme.textMuted, size: 32),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              HabitCheckbox(
                label: 'Answer Template Written',
                checked: answered,
                onToggle: () => setModal(() => answered = !answered),
                icon: Icons.draw_outlined,
                color: AppTheme.success,
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  await provider.updateThinkerMastery(thinker['id'] as int, mastery, answered);
                  _loadThinkers();
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
