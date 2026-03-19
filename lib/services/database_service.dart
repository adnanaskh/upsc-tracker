import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'upsc_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Study sessions table
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        subject TEXT NOT NULL,
        topic TEXT,
        book TEXT,
        duration_minutes INTEGER DEFAULT 0,
        pages_covered INTEGER DEFAULT 0,
        notes TEXT,
        phase INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Daily habits tracking
    await db.execute('''
      CREATE TABLE daily_habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        morning_study INTEGER DEFAULT 0,
        chapter_notes INTEGER DEFAULT 0,
        mcq_practice INTEGER DEFAULT 0,
        answer_writing INTEGER DEFAULT 0,
        newspaper_read INTEGER DEFAULT 0,
        ignou_reading INTEGER DEFAULT 0,
        physical_health INTEGER DEFAULT 0,
        total_minutes INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Books tracker
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        subject TEXT,
        phase INTEGER,
        total_chapters INTEGER DEFAULT 0,
        chapters_completed INTEGER DEFAULT 0,
        total_pages INTEGER DEFAULT 0,
        pages_read INTEGER DEFAULT 0,
        status TEXT DEFAULT 'not_started',
        start_date TEXT,
        completion_date TEXT,
        notes TEXT,
        buy_month TEXT,
        is_custom INTEGER DEFAULT 0
      )
    ''');

    // Goals / targets
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        subject TEXT,
        target_date TEXT,
        completed INTEGER DEFAULT 0,
        completion_date TEXT,
        priority TEXT DEFAULT 'medium',
        phase INTEGER DEFAULT 1
      )
    ''');

    // Daily planner tasks
    await db.execute('''
      CREATE TABLE planner_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        subject TEXT,
        duration_minutes INTEGER DEFAULT 60,
        completed INTEGER DEFAULT 0,
        order_index INTEGER DEFAULT 0,
        task_type TEXT DEFAULT 'study'
      )
    ''');

    // MCQ test results
    await db.execute('''
      CREATE TABLE mcq_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        subject TEXT,
        total_questions INTEGER,
        correct INTEGER,
        incorrect INTEGER,
        notes TEXT,
        phase INTEGER DEFAULT 1
      )
    ''');

    // Answer writing logs
    await db.execute('''
      CREATE TABLE answer_writing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        topic TEXT,
        subject TEXT,
        paper TEXT,
        word_count INTEGER,
        self_score INTEGER,
        notes TEXT
      )
    ''');

    // Thinkers mastery
    await db.execute('''
      CREATE TABLE thinkers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        priority TEXT DEFAULT 'medium',
        paper TEXT,
        key_concepts TEXT,
        mastery_level INTEGER DEFAULT 0,
        answer_written INTEGER DEFAULT 0,
        last_revised TEXT,
        ignou_ref TEXT
      )
    ''');

    // Settings / user profile
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert default books from the planner
    await _insertDefaultBooks(db);
    await _insertDefaultThinkers(db);
    await _insertDefaultSettings(db);
  }

  Future<void> _insertDefaultBooks(Database db) async {
    final books = [
      // Phase 1
      {'title': 'Ancient India (Old NCERT)', 'author': 'RS Sharma', 'subject': 'History', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 25},
      {'title': 'Medieval India (Old NCERT)', 'author': 'Satish Chandra', 'subject': 'History', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 30},
      {'title': 'Modern India (Old NCERT)', 'author': 'Bipin Chandra', 'subject': 'History', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 20},
      {'title': 'A Brief History of Modern India', 'author': 'Rajiv Ahir / Spectrum', 'subject': 'History', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 22},
      {'title': 'NCERT Sociology Class 11 (Understanding Society)', 'author': 'NCERT', 'subject': 'Sociology', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 6},
      {'title': 'NCERT Sociology Class 12 (Indian Society)', 'author': 'NCERT', 'subject': 'Sociology', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 6},
      {'title': 'NCERT Sociology Class 12 (Social Change)', 'author': 'NCERT', 'subject': 'Sociology', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 6},
      {'title': 'NCERT Physical Geography Class 11', 'author': 'NCERT', 'subject': 'Geography', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 16},
      {'title': 'NCERT Human Geography Class 12', 'author': 'NCERT', 'subject': 'Geography', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 12},
      {'title': 'Certificate Physical & Human Geography', 'author': 'Goh Cheng Leong', 'subject': 'Geography', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 35},
      {'title': 'Atlas for Competitive Exams', 'author': 'Orient Black Swan', 'subject': 'Geography', 'phase': 1, 'buy_month': 'Mar 2026'},
      {'title': 'NCERT Indian Constitution at Work (Cl.11)', 'author': 'NCERT', 'subject': 'Polity', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 10},
      {'title': 'NCERT Political Theory (Cl.11)', 'author': 'NCERT', 'subject': 'Polity', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 10},
      {'title': 'NCERT Politics in India Since Independence (Cl.12)', 'author': 'NCERT', 'subject': 'Polity', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 9},
      {'title': 'NCERT Contemporary World Politics (Cl.12)', 'author': 'NCERT', 'subject': 'Polity', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 9},
      {'title': 'NCERT Indian Economic Development (Cl.11)', 'author': 'NCERT', 'subject': 'Economy', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 10},
      {'title': 'Introduction to Indian Art (Cl.11)', 'author': 'NCERT', 'subject': 'Art & Culture', 'phase': 1, 'buy_month': 'Mar 2026', 'total_chapters': 12},
      // IGNOU BA
      {'title': 'ESO-11: The Study of Society', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 1, 'buy_month': 'Nov 2026 (free PDF)', 'total_chapters': 10},
      {'title': 'ESO-12: Society in India', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'Mar 2027 (free PDF)', 'total_chapters': 10},
      {'title': 'ESO-13: Sociological Thought', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'Mar 2027 (free PDF)', 'total_chapters': 10},
      {'title': 'ESO-14: Society and Stratification', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'May 2027 (free PDF)', 'total_chapters': 10},
      {'title': 'ESO-15: Society and Religion', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'May 2027 (free PDF)', 'total_chapters': 10},
      {'title': 'ESO-16: Social Change in Modern Society', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'Jul 2027 (free PDF)', 'total_chapters': 10},
      // Phase 2
      {'title': 'Indian Polity 8e', 'author': 'M. Laxmikanth', 'subject': 'Polity', 'phase': 2, 'buy_month': 'Jan 2027', 'total_chapters': 80},
      {'title': 'Introduction to Constitution of India 27e', 'author': 'D.D. Basu', 'subject': 'Polity', 'phase': 2, 'buy_month': 'Jan 2027', 'total_chapters': 40},
      {'title': 'Indian Economy 6e', 'author': 'Nitin Singhania', 'subject': 'Economy', 'phase': 2, 'buy_month': 'Mar 2027', 'total_chapters': 30},
      {'title': 'Indian Art and Culture 6e', 'author': 'Nitin Singhania', 'subject': 'Art & Culture', 'phase': 2, 'buy_month': 'May 2027', 'total_chapters': 25},
      {'title': 'Modernization of Indian Tradition', 'author': 'Yogendra Singh', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'Mar 2027', 'total_chapters': 12},
      {'title': 'Indian Sociological Thought 2e', 'author': 'B.K. Nagla', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'Mar 2027', 'total_chapters': 15},
      {'title': 'Essential Sociology', 'author': 'Genius Kids Blue', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'May 2027', 'total_chapters': 20},
      {'title': 'Lexicon — Ethics, Integrity & Aptitude', 'author': 'Chronicle / Niraj Kumar', 'subject': 'Ethics', 'phase': 2, 'buy_month': 'Sep 2027', 'total_chapters': 20},
      // IGNOU MA
      {'title': 'MSO-1: Sociological Theories & Concepts', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'Sep 2027 (free PDF)', 'total_chapters': 12},
      {'title': 'MSO-2: Research Methods & Analysis', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 2, 'buy_month': 'Nov 2027 (free PDF)', 'total_chapters': 12},
      {'title': 'MSO-3: Sociology of Development & Change', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 3, 'buy_month': 'Jan 2028 (free PDF)', 'total_chapters': 12},
      {'title': 'MSO-4: Sociology of India', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 3, 'buy_month': 'Jan 2028 (free PDF)', 'total_chapters': 12},
      {'title': 'MSOE-1: India and the World', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 3, 'buy_month': 'Jan 2028 (free PDF)', 'total_chapters': 12},
      {'title': 'MSOE-2: Diaspora & Transnational Communities', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 3, 'buy_month': 'Mar 2028 (free PDF)', 'total_chapters': 12},
      {'title': 'MSOE-3: Sociology of Organizations & Work', 'author': 'IGNOU', 'subject': 'Sociology', 'phase': 3, 'buy_month': 'May 2028 (free PDF)', 'total_chapters': 12},
      // Phase 3
      {'title': 'Internal Security for UPSC CSE', 'author': 'Nitin Singhania', 'subject': 'Current Affairs', 'phase': 3, 'buy_month': 'Jan 2028', 'total_chapters': 20},
      {'title': 'Environment and Ecology for UPSC', 'author': 'Shankar IAS', 'subject': 'Environment', 'phase': 3, 'buy_month': 'Jan 2028', 'total_chapters': 18},
      {'title': 'Science and Technology for UPSC', 'author': 'Ravi P. Agrahari', 'subject': 'Science & Tech', 'phase': 3, 'buy_month': 'Jan 2028', 'total_chapters': 20},
    ];

    for (final book in books) {
      await db.insert('books', {
        'title': book['title'],
        'author': book['author'] ?? '',
        'subject': book['subject'] ?? '',
        'phase': book['phase'] ?? 1,
        'buy_month': book['buy_month'] ?? '',
        'total_chapters': book['total_chapters'] ?? 0,
        'chapters_completed': 0,
        'status': 'not_started',
        'is_custom': 0,
      });
    }
  }

  Future<void> _insertDefaultThinkers(Database db) async {
    final thinkers = [
      {'name': 'Karl Marx', 'priority': 'very_high', 'paper': 'Paper 1', 'key_concepts': 'Historical materialism, class struggle, alienation, surplus value, base-superstructure', 'ignou_ref': 'MSO-1, MSO-2'},
      {'name': 'Max Weber', 'priority': 'very_high', 'paper': 'Paper 1', 'key_concepts': 'Ideal types, rationalization, authority types, Protestant Ethic, bureaucracy', 'ignou_ref': 'MSO-1, ESO-13'},
      {'name': 'Emile Durkheim', 'priority': 'very_high', 'paper': 'Paper 1', 'key_concepts': 'Social facts, suicide typology, mechanical & organic solidarity, religion', 'ignou_ref': 'MSO-1, ESO-13'},
      {'name': 'Talcott Parsons', 'priority': 'high', 'paper': 'Paper 1', 'key_concepts': 'Structural functionalism, AGIL scheme, pattern variables, social system', 'ignou_ref': 'MSO-1'},
      {'name': 'Robert Merton', 'priority': 'high', 'paper': 'Paper 1', 'key_concepts': 'Manifest/latent functions, dysfunctions, anomie, reference group', 'ignou_ref': 'MSO-1, ESO-11'},
      {'name': 'Auguste Comte', 'priority': 'high', 'paper': 'Paper 1', 'key_concepts': 'Positivism, law of three stages, social statics and dynamics', 'ignou_ref': 'ESO-13'},
      {'name': 'Herbert Spencer', 'priority': 'medium', 'paper': 'Paper 1', 'key_concepts': 'Organic analogy, social Darwinism, evolutionary theory', 'ignou_ref': 'ESO-13'},
      {'name': 'Pierre Bourdieu', 'priority': 'high', 'paper': 'Paper 1', 'key_concepts': 'Habitus, field, cultural capital, social reproduction', 'ignou_ref': 'MSO-1'},
      {'name': 'Anthony Giddens', 'priority': 'medium', 'paper': 'Paper 1', 'key_concepts': 'Structuration theory, agency and structure, late modernity', 'ignou_ref': 'MSO-1'},
      {'name': 'Michel Foucault', 'priority': 'medium', 'paper': 'Paper 1', 'key_concepts': 'Power-knowledge, discourse, discipline, post-structuralism', 'ignou_ref': 'MSO-1'},
      {'name': 'M.N. Srinivas', 'priority': 'very_high', 'paper': 'Paper 2', 'key_concepts': 'Sanskritization, dominant caste, Westernization, village studies', 'ignou_ref': 'ESO-14, ESO-16'},
      {'name': 'Yogendra Singh', 'priority': 'very_high', 'paper': 'Paper 2', 'key_concepts': 'Modernization of Indian tradition, great and little tradition', 'ignou_ref': 'ESO-16'},
      {'name': 'Louis Dumont', 'priority': 'high', 'paper': 'Paper 2', 'key_concepts': 'Homo Hierarchicus, caste as ideology, holism vs individualism', 'ignou_ref': 'ESO-14'},
      {'name': 'G.S. Ghurye', 'priority': 'high', 'paper': 'Paper 2', 'key_concepts': 'Caste features, tribes as backward Hindus, Hinduism and culture', 'ignou_ref': 'ESO-14'},
      {'name': 'B.R. Ambedkar', 'priority': 'very_high', 'paper': 'Paper 2', 'key_concepts': 'Annihilation of caste, Dalit identity, Buddhism, constitutional vision', 'ignou_ref': 'MSO-4, ESO-14'},
      {'name': 'A.R. Desai', 'priority': 'high', 'paper': 'Paper 2', 'key_concepts': 'Agrarian social structure, state, nationalism, Marxist approach', 'ignou_ref': 'ESO-14'},
      {'name': 'Andre Beteille', 'priority': 'medium', 'paper': 'Paper 2', 'key_concepts': 'Caste, class and power, inequality, comparative sociology', 'ignou_ref': 'MSO-4'},
      {'name': 'Immanuel Wallerstein', 'priority': 'medium', 'paper': 'Paper 1', 'key_concepts': 'World system theory, core-periphery, capitalist world economy', 'ignou_ref': 'MSO-3'},
    ];

    for (final t in thinkers) {
      await db.insert('thinkers', {
        'name': t['name'],
        'priority': t['priority'],
        'paper': t['paper'],
        'key_concepts': t['key_concepts'],
        'ignou_ref': t['ignou_ref'],
        'mastery_level': 0,
        'answer_written': 0,
      });
    }
  }

  Future<void> _insertDefaultSettings(Database db) async {
    await db.insert('settings', {'key': 'user_name', 'value': 'Adnan Ahmad'});
    await db.insert('settings', {'key': 'target_exam', 'value': 'UPSC CSE 2029'});
    await db.insert('settings', {'key': 'optional', 'value': 'Sociology'});
    await db.insert('settings', {'key': 'start_date', 'value': '2026-04-01'});
    await db.insert('settings', {'key': 'current_phase', 'value': '1'});
    await db.insert('settings', {'key': 'daily_target_minutes', 'value': '120'});
    await db.insert('settings', {'key': 'morning_alarm_enabled', 'value': 'true'});
    await db.insert('settings', {'key': 'morning_alarm_time', 'value': '05:30'});
  }

  // ---- CRUD operations ----

  // Study sessions
  Future<int> insertStudySession(Map<String, dynamic> session) async {
    final database = await db;
    return await database.insert('study_sessions', session);
  }

  Future<List<Map<String, dynamic>>> getStudySessions({String? date, String? subject}) async {
    final database = await db;
    String where = '';
    List<dynamic> args = [];
    if (date != null) { where += 'date = ?'; args.add(date); }
    if (subject != null) {
      where += where.isNotEmpty ? ' AND subject = ?' : 'subject = ?';
      args.add(subject);
    }
    return await database.query('study_sessions',
        where: where.isNotEmpty ? where : null,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'created_at DESC');
  }

  Future<int> getTotalStudyMinutes({String? subject, String? fromDate, String? toDate}) async {
    final database = await db;
    String where = '1=1';
    List<dynamic> args = [];
    if (subject != null) { where += ' AND subject = ?'; args.add(subject); }
    if (fromDate != null) { where += ' AND date >= ?'; args.add(fromDate); }
    if (toDate != null) { where += ' AND date <= ?'; args.add(toDate); }
    final result = await database.rawQuery(
        'SELECT SUM(duration_minutes) as total FROM study_sessions WHERE $where', args);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  // Daily habits
  Future<Map<String, dynamic>?> getDailyHabits(String date) async {
    final database = await db;
    final result = await database.query('daily_habits', where: 'date = ?', whereArgs: [date]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> upsertDailyHabits(Map<String, dynamic> habits) async {
    final database = await db;
    final existing = await getDailyHabits(habits['date']);
    if (existing != null) {
      await database.update('daily_habits', habits, where: 'date = ?', whereArgs: [habits['date']]);
    } else {
      await database.insert('daily_habits', habits);
    }
  }

  // Streak calculation
  Future<int> getCurrentStreak() async {
    final database = await db;
    final results = await database.query('daily_habits',
        orderBy: 'date DESC', limit: 365);
    if (results.isEmpty) return 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (final row in results) {
      final rowDate = DateTime.parse(row['date'] as String);
      final diff = checkDate.difference(rowDate).inDays;
      if (diff <= 1 && (row['total_minutes'] as int) > 0) {
        streak++;
        checkDate = rowDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<int> getLongestStreak() async {
    final database = await db;
    final results = await database.query('daily_habits',
        where: 'total_minutes > 0', orderBy: 'date ASC');
    if (results.isEmpty) return 0;
    int longest = 0, current = 1;
    for (int i = 1; i < results.length; i++) {
      final prev = DateTime.parse(results[i - 1]['date'] as String);
      final curr = DateTime.parse(results[i]['date'] as String);
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest > 0 ? longest : (results.isNotEmpty ? 1 : 0);
  }

  // Books
  Future<List<Map<String, dynamic>>> getBooks({int? phase, String? subject, String? status}) async {
    final database = await db;
    String where = '1=1';
    List<dynamic> args = [];
    if (phase != null) { where += ' AND phase = ?'; args.add(phase); }
    if (subject != null) { where += ' AND subject = ?'; args.add(subject); }
    if (status != null) { where += ' AND status = ?'; args.add(status); }
    return await database.query('books', where: where, whereArgs: args, orderBy: 'phase, subject');
  }

  Future<void> updateBook(int id, Map<String, dynamic> updates) async {
    final database = await db;
    await database.update('books', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBook(Map<String, dynamic> book) async {
    final database = await db;
    return await database.insert('books', book);
  }

  // Goals
  Future<List<Map<String, dynamic>>> getGoals({int? phase, bool? completed}) async {
    final database = await db;
    String where = '1=1';
    List<dynamic> args = [];
    if (phase != null) { where += ' AND phase = ?'; args.add(phase); }
    if (completed != null) { where += ' AND completed = ?'; args.add(completed ? 1 : 0); }
    return await database.query('goals', where: where, whereArgs: args, orderBy: 'target_date');
  }

  Future<int> insertGoal(Map<String, dynamic> goal) async {
    final database = await db;
    return await database.insert('goals', goal);
  }

  Future<void> updateGoal(int id, Map<String, dynamic> updates) async {
    final database = await db;
    await database.update('goals', updates, where: 'id = ?', whereArgs: [id]);
  }

  // Planner tasks
  Future<List<Map<String, dynamic>>> getPlannerTasks(String date) async {
    final database = await db;
    return await database.query('planner_tasks',
        where: 'date = ?', whereArgs: [date], orderBy: 'order_index');
  }

  Future<int> insertPlannerTask(Map<String, dynamic> task) async {
    final database = await db;
    return await database.insert('planner_tasks', task);
  }

  Future<void> updatePlannerTask(int id, Map<String, dynamic> updates) async {
    final database = await db;
    await database.update('planner_tasks', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlannerTask(int id) async {
    final database = await db;
    await database.delete('planner_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // MCQ Tests
  Future<int> insertMcqTest(Map<String, dynamic> test) async {
    final database = await db;
    return await database.insert('mcq_tests', test);
  }

  Future<List<Map<String, dynamic>>> getMcqTests({String? subject}) async {
    final database = await db;
    return await database.query('mcq_tests',
        where: subject != null ? 'subject = ?' : null,
        whereArgs: subject != null ? [subject] : null,
        orderBy: 'date DESC');
  }

  // Answer writing
  Future<int> insertAnswerWriting(Map<String, dynamic> entry) async {
    final database = await db;
    return await database.insert('answer_writing', entry);
  }

  Future<List<Map<String, dynamic>>> getAnswerWriting({String? subject}) async {
    final database = await db;
    return await database.query('answer_writing',
        where: subject != null ? 'subject = ?' : null,
        whereArgs: subject != null ? [subject] : null,
        orderBy: 'date DESC');
  }

  // Thinkers
  Future<List<Map<String, dynamic>>> getThinkers({String? paper, String? priority}) async {
    final database = await db;
    String where = '1=1';
    List<dynamic> args = [];
    if (paper != null) { where += ' AND paper = ?'; args.add(paper); }
    if (priority != null) { where += ' AND priority = ?'; args.add(priority); }
    return await database.query('thinkers', where: where, whereArgs: args, orderBy: 'priority DESC, name');
  }

  Future<void> updateThinker(int id, Map<String, dynamic> updates) async {
    final database = await db;
    await database.update('thinkers', updates, where: 'id = ?', whereArgs: [id]);
  }

  // Settings
  Future<String?> getSetting(String key) async {
    final database = await db;
    final result = await database.query('settings', where: 'key = ?', whereArgs: [key]);
    return result.isNotEmpty ? result.first['value'] as String? : null;
  }

  Future<void> setSetting(String key, String value) async {
    final database = await db;
    await database.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Statistics
  Future<Map<String, int>> getSubjectWiseMinutes({String? fromDate, String? toDate}) async {
    final database = await db;
    String where = '1=1';
    List<dynamic> args = [];
    if (fromDate != null) { where += ' AND date >= ?'; args.add(fromDate); }
    if (toDate != null) { where += ' AND date <= ?'; args.add(toDate); }
    final result = await database.rawQuery(
        'SELECT subject, SUM(duration_minutes) as total FROM study_sessions WHERE $where GROUP BY subject',
        args);
    final map = <String, int>{};
    for (final row in result) {
      map[row['subject'] as String] = (row['total'] as num).toInt();
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStudyData() async {
    final database = await db;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
    final fromDate = sevenDaysAgo.toIso8601String().substring(0, 10);
    return await database.rawQuery('''
      SELECT date, SUM(duration_minutes) as total
      FROM study_sessions
      WHERE date >= ?
      GROUP BY date
      ORDER BY date
    ''', [fromDate]);
  }

  Future<int> getTotalDaysStudied() async {
    final database = await db;
    final result = await database.rawQuery(
        'SELECT COUNT(DISTINCT date) as count FROM study_sessions');
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }
}
