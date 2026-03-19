import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});
  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabController;
  int _selectedPhase = 0; // 0 = all
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedPhase = _tabController.index);
      _loadBooks();
    });
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    final books = await _db.getBooks(phase: _selectedPhase == 0 ? null : _selectedPhase);
    setState(() { _books = books; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Book Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBookDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Phase 1'),
            Tab(text: 'Phase 2'),
            Tab(text: 'Phase 3'),
            Tab(text: 'Phase 4'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip('all', 'All'),
                  const SizedBox(width: 8),
                  _statusChip('not_started', 'Not Started'),
                  const SizedBox(width: 8),
                  _statusChip('in_progress', 'Reading'),
                  const SizedBox(width: 8),
                  _statusChip('completed', 'Done'),
                ],
              ),
            ),
          ),

          // Stats bar
          _buildStatsBar(),

          // Books list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _buildBooksList(provider),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppTheme.primary : AppTheme.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildStatsBar() {
    final filtered = _filteredBooks;
    final total = filtered.length;
    final completed = filtered.where((b) => b['status'] == 'completed').length;
    final inProgress = filtered.where((b) => b['status'] == 'in_progress').length;
    final notStarted = filtered.where((b) => b['status'] == 'not_started').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          _statPill('$completed', 'Done', AppTheme.success),
          const SizedBox(width: 10),
          _statPill('$inProgress', 'Reading', AppTheme.warning),
          const SizedBox(width: 10),
          _statPill('$notStarted', 'Pending', AppTheme.textMuted),
          const Spacer(),
          Text('$total books total', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$value $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  List<Map<String, dynamic>> get _filteredBooks {
    if (_selectedStatus == 'all') return _books;
    return _books.where((b) => b['status'] == _selectedStatus).toList();
  }

  Widget _buildBooksList(AppProvider provider) {
    final books = _filteredBooks;
    if (books.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book,
        title: 'No Books Found',
        subtitle: 'Try a different filter or add a book',
        actionLabel: 'Add Book',
        onAction: () => _showAddBookDialog(context),
      );
    }

    // Group by subject
    final subjects = <String, List<Map<String, dynamic>>>{};
    for (final book in books) {
      final subject = book['subject'] as String? ?? 'Other';
      subjects[subject] = (subjects[subject] ?? [])..add(book);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: subjects.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: SubjectBadge(subject: entry.key),
            ),
            ...entry.value.map((book) => _buildBookCard(book, provider)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, AppProvider provider) {
    final status = book['status'] as String;
    final totalChapters = (book['total_chapters'] as int?) ?? 0;
    final doneChapters = (book['chapters_completed'] as int?) ?? 0;
    final progress = totalChapters > 0 ? doneChapters / totalChapters : 0.0;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed': statusColor = AppTheme.success; statusIcon = Icons.check_circle; break;
      case 'in_progress': statusColor = AppTheme.warning; statusIcon = Icons.auto_stories; break;
      default: statusColor = AppTheme.textMuted; statusIcon = Icons.book_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => _showBookDetailDialog(context, book, provider),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book['title'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(book['author'] as String? ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                PhaseBadge(phase: (book['phase'] as int?) ?? 1),
              ],
            ),
            if (totalChapters > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.toDouble(),
                        backgroundColor: AppTheme.surfaceVariant,
                        color: statusColor,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$doneChapters/$totalChapters ch', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
            if ((book['buy_month'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('Buy: ${book['buy_month']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBookDetailDialog(BuildContext context, Map<String, dynamic> book, AppProvider provider) {
    int chapters = (book['chapters_completed'] as int?) ?? 0;
    String status = book['status'] as String;
    final totalChapters = (book['total_chapters'] as int?) ?? 0;

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
              Text(book['title'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              Text(book['author'] as String? ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              const Text('Status', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusButton(ctx, 'not_started', 'Not Started', status, (v) => setModal(() => status = v)),
                  const SizedBox(width: 8),
                  _statusButton(ctx, 'in_progress', 'Reading', status, (v) => setModal(() => status = v)),
                  const SizedBox(width: 8),
                  _statusButton(ctx, 'completed', 'Done ✓', status, (v) => setModal(() => status = v)),
                ],
              ),
              if (totalChapters > 0) ...[
                const SizedBox(height: 16),
                Text('Chapters: $chapters / $totalChapters', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () { if (chapters > 0) setModal(() => chapters--); },
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                    ),
                    Expanded(
                      child: Slider(
                        value: chapters.toDouble(),
                        max: totalChapters.toDouble(),
                        divisions: totalChapters,
                        activeColor: AppTheme.primary,
                        inactiveColor: AppTheme.surfaceVariant,
                        onChanged: (v) => setModal(() => chapters = v.toInt()),
                      ),
                    ),
                    IconButton(
                      onPressed: () { if (chapters < totalChapters) setModal(() => chapters++); },
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await provider.updateBookProgress(book['id'] as int,
                        chaptersCompleted: chapters, status: status);
                    _loadBooks();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Progress'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusButton(BuildContext ctx, String value, String label, String current, Function(String) onSelect) {
    final selected = current == value;
    Color color;
    switch (value) {
      case 'completed': color = AppTheme.success; break;
      case 'in_progress': color = AppTheme.warning; break;
      default: color = AppTheme.textMuted;
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.transparent),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? color : AppTheme.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ),
      ),
    );
  }

  void _showAddBookDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    String subject = 'History';
    int phase = 1;
    int totalChapters = 0;
    String buyMonth = '';

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
                const Text('Add Custom Book', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Book title *')),
                const SizedBox(height: 10),
                TextField(controller: authorCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Author')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: subject,
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                  items: ['History', 'Geography', 'Polity', 'Economy', 'Sociology', 'Ethics', 'Art & Culture', 'Science & Tech', 'Environment', 'Current Affairs', 'CSAT', 'Essay']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModal(() => subject = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: phase,
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Phase', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                  items: [1, 2, 3, 4].map((p) => DropdownMenuItem(value: p, child: Text('Phase $p'))).toList(),
                  onChanged: (v) => setModal(() => phase = v!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      await _db.insertBook({
                        'title': titleCtrl.text.trim(),
                        'author': authorCtrl.text.trim(),
                        'subject': subject,
                        'phase': phase,
                        'total_chapters': totalChapters,
                        'chapters_completed': 0,
                        'status': 'not_started',
                        'is_custom': 1,
                        'buy_month': buyMonth,
                      });
                      _loadBooks();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add Book'),
                  ),
                ),
              ],
            ),
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
