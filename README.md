# 🎯 UPSC CSE 2029 Tracker — Adnan Ahmad

A complete, fully offline Android app to track your 3-year UPSC preparation journey (April 2026 → IAS 2029).

---

## ✅ Features

### Home Screen
- 🔥 **Streak counter** — front and center, daily streak + best streak
- 📊 Today's study progress ring (minutes logged vs. daily target)
- 📋 Today's tasks checklist (from planner)
- ✅ Daily habits tracker: Morning 5:30 AM, Chapter notes, MCQ, Answer writing, Newspaper, IGNOU, Walk/Sleep
- ⏳ Countdown: Days/Weeks/Months to UPSC Prelims ~Jun 2029

### Daily Planner
- 📅 Calendar view — pick any day
- ➕ Add tasks with subject, duration
- ✅ Check off completed tasks
- 🔄 Drag to reorder, swipe to delete

### Books Tracker (40 books pre-loaded)
- All Phase 1, 2, 3 books + all IGNOU BA/MA books pre-populated
- Track status: Not Started → Reading → Done
- Chapter-by-chapter progress slider
- Filter by Phase (1–4), Subject, Status
- ➕ Add custom books

### Statistics
- 📊 Weekly study bar chart (last 7 days)
- 🍩 Subject-wise pie chart
- 📈 Phase progress tracker
- 🧪 MCQ test log + accuracy tracking
- ✍️ Answer writing log with self-score

### Goals & Targets
- Add study goals with priority, target date, subject
- Phase-wise goal tracking
- Completed goals archive

### Sociology Thinkers (18 pre-loaded)
- Paper 1: Marx, Weber, Durkheim, Parsons, Merton, Comte, Spencer, Bourdieu, Giddens, Foucault, Wallerstein
- Paper 2: MN Srinivas, Yogendra Singh, Dumont, Ghurye, Ambedkar, AR Desai, Beteille
- ⭐ 1–5 star mastery rating per thinker
- ✅ Track answer templates written
- IGNOU reference for each thinker

### Reminders & Notifications
- ⏰ **5:30 AM morning study alarm** (daily, configurable time)
- 📝 9:00 PM evening log reminder
- 🧪 Sunday 7 PM planning + 8 PM self-test reminder
- 📊 Monthly review on last day of month
- 🔥 Streak milestone alerts (7, 30, 100 days)

---

## 🏗️ Tech Stack

- **Flutter 3.x** + Dart
- **SQLite** via sqflite — 100% offline, no cloud
- **Provider** — state management
- **flutter_local_notifications** — all reminders
- **fl_chart** — statistics charts
- **table_calendar** — planner calendar
- **percent_indicator** — progress rings

---

## 📦 Build Instructions

### Prerequisites
```bash
# Install Flutter SDK (if not installed)
# https://flutter.dev/docs/get-started/install

flutter --version  # Needs 3.10+
```

### One-Command Build (APK)
```bash
# 1. Extract the zip anywhere
cd upsc_tracker

# 2. Get dependencies
flutter pub get

# 3. Build debug APK (fastest)
flutter build apk --debug

# 4. Install on connected Android device
flutter install

# OR build release APK
flutter build apk --release
```

APK location after build:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### Run on Emulator / Device
```bash
flutter devices          # List connected devices
flutter run -d <device>  # Run on specific device
```

### Transfer APK to Phone
```bash
# Copy APK to phone via USB, then install manually
# Enable "Install from unknown sources" in phone settings first
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📱 First Launch

On first launch the app pre-loads:
- **40 books** across Phase 1, 2, 3 (including all IGNOU BA/MA PDFs)
- **18 Sociology thinkers** with key concepts and IGNOU references
- Your profile: Adnan Ahmad · UPSC CSE 2029 · Sociology Optional
- Default alarm: 5:30 AM (can change in Settings)

---

## 📂 Project Structure

```
lib/
├── main.dart                    # Entry point + splash
├── theme/app_theme.dart         # Dark theme + colors
├── providers/app_provider.dart  # All state management
├── services/
│   ├── database_service.dart    # SQLite CRUD + all data
│   └── notification_service.dart
├── screens/
│   ├── main_navigator.dart      # Bottom nav
│   ├── home_screen.dart         # Dashboard
│   ├── planner_screen.dart      # Daily planner + calendar
│   ├── books_screen.dart        # Book tracker
│   ├── stats_screen.dart        # Charts + MCQ + answer log
│   ├── goals_screen.dart        # Goals/targets
│   ├── thinkers_screen.dart     # Sociology thinkers
│   ├── settings_screen.dart     # Alarms + preferences
│   └── log_session_screen.dart  # Log a study session
└── widgets/common_widgets.dart  # Shared UI components
```

---

## 🗓️ 4-Phase Roadmap Pre-loaded

| Phase | Period | Focus | Weekly Hours |
|-------|--------|-------|-------------|
| 1 | Mar–Dec 2026 | NCERT + Foundation | ~20h |
| 2 | Jan–Dec 2027 | Reference books + IGNOU | ~22h |
| 3 | Jan–Sep 2028 | Current affairs + Answer writing | ~22h |
| 4 | Oct 2028–2029 | Revision + Mocks | ~28–30h |

---

## 📚 Pre-loaded Books (40 total)

**Phase 1 (17 books):** RS Sharma, Satish Chandra, Bipin Chandra, Spectrum, NCERTs (Sociology, Geography, Polity, Economy, Art), Goh Cheng Leong, Orient Black Swan Atlas

**Phase 2 (15 books):** Laxmikanth, DD Basu, Nitin Singhania (Economy + Art), Yogendra Singh, BK Nagla, Genius Kids, Lexicon Ethics, IGNOU BA (ESO 11–16), IGNOU MA (MSO 1–4)

**Phase 3 (8 books):** Singhania Internal Security, Shankar Environment, Ravi Agrahari S&T, IGNOU MA electives (MSOE 1–3)

---

## 🧠 Sociology Thinkers Framework (TDIA)

Every thinker is tracked using:
- **T** — Theory / Concept
- **D** — Definition & key ideas
- **I** — Indian application
- **A** — Answer template written ✅

---

*"Consistency beats intensity — 2 hours daily for 3 years beats 14 hours for 3 months. Inshallah, IAS 2029."*
