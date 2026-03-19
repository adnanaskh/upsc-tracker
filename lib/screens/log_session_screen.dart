import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/database_service.dart';

class LogSessionScreen extends StatefulWidget {
  const LogSessionScreen({super.key});
  @override
  State<LogSessionScreen> createState() => _LogSessionScreenState();
}

class _LogSessionScreenState extends State<LogSessionScreen> {
  final _db = DatabaseService();
  String _selectedSubject = 'History';
  final _topicController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedBook;
  int _durationMinutes = 60;
  int _pagesCovered = 0;
  bool _saving = false;
  List<Map<String, dynamic>> _books = [];

  final subjects = [
    'History', 'Geography', 'Polity', 'Economy',
    'Sociology', 'Ethics', 'Art & Culture', 'Science & Tech',
    'Environment', 'Current Affairs', 'CSAT', 'Essay',
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await _db.getBooks(subject: _selectedSubject);
    setState(() => _books = books);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Log Study Session'),
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject selector
            const Text('Subject', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects.map((s) {
                final selected = _selectedSubject == s;
                final color = AppTheme.subjectColors[s] ?? AppTheme.primary;
                return GestureDetector(
                  onTap: () {
                    setState(() { _selectedSubject = s; _selectedBook = null; });
                    _loadBooks();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
                    ),
                    child: Text(s, style: TextStyle(color: selected ? color : AppTheme.textSecondary, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Book selector
            if (_books.isNotEmpty) ...[
              const Text('Book (optional)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBook,
                dropdownColor: AppTheme.card,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Select book...'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._books.map((b) => DropdownMenuItem(
                    value: b['title'] as String,
                    child: Text(b['title'] as String, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (v) => setState(() => _selectedBook = v),
              ),
              const SizedBox(height: 20),
            ],

            // Topic
            const Text('Topic / Chapter', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'e.g. Indus Valley Civilization, Marx - Alienation...'),
            ),
            const SizedBox(height: 20),

            // Duration
            const Text('Duration (minutes)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () { if (_durationMinutes > 15) setState(() => _durationMinutes -= 15); },
                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('$_durationMinutes min', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                        Text(_formatDuration(_durationMinutes), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () { if (_durationMinutes < 600) setState(() => _durationMinutes += 15); },
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Quick duration chips
            Wrap(
              spacing: 8,
              children: [30, 60, 90, 120, 150, 180].map((d) {
                return ActionChip(
                  label: Text('${d}m'),
                  onPressed: () => setState(() => _durationMinutes = d),
                  backgroundColor: _durationMinutes == d ? AppTheme.primary.withOpacity(0.3) : AppTheme.surfaceVariant,
                  labelStyle: TextStyle(color: _durationMinutes == d ? AppTheme.primary : AppTheme.textSecondary, fontSize: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Pages covered
            const Text('Pages / Chapters covered', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () { if (_pagesCovered > 0) setState(() => _pagesCovered--); },
                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                  ),
                  Expanded(
                    child: Text('$_pagesCovered', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _pagesCovered++),
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            const Text('Notes (optional)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'Key takeaways, doubts, important points...'),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes minutes';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    await provider.logStudySession(
      subject: _selectedSubject,
      durationMinutes: _durationMinutes,
      topic: _topicController.text.trim(),
      book: _selectedBook,
      pagesCovered: _pagesCovered,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Session logged! +$_durationMinutes minutes for $_selectedSubject'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
