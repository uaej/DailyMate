import 'package:flutter/foundation.dart';

class RoutineItem {
  final String title;
  final Duration duration;
  bool completed;

  RoutineItem({required this.title, required this.duration, this.completed = false});
}

class TimelineEvent {
  final String id;
  final String title;
  final DateTime start;
  final Duration duration;
  final String source; // e.g., 'calendar', 'routine', 'ai'

  TimelineEvent({required this.id, required this.title, required this.start, required this.duration, required this.source});
}

class HomeViewModel extends ChangeNotifier {
  String todaySummary = '미팅 2개 · 공부 1시간 · 사이드 프로젝트 1개';
  String todayGoal = '편입 공부 2시간을 확보하기';

  List<RoutineItem> morningRoutines = [
    RoutineItem(title: '영양제', duration: const Duration(minutes: 5)),
    RoutineItem(title: '운동', duration: const Duration(minutes: 20)),
    RoutineItem(title: '공부', duration: const Duration(hours: 1)),
  ];

  List<TimelineEvent> timeline = [];
  // store completion state by event id
  final Map<String, bool> _eventCompletion = {};

  HomeViewModel() {
    _generateMockTimeline();
  }

  void _generateMockTimeline() {
    final now = DateTime.now();
    timeline = [
      TimelineEvent(id: '${DateTime(now.year, now.month, now.day, 7, 30).millisecondsSinceEpoch}-a', title: '아침 루틴', start: DateTime(now.year, now.month, now.day, 7, 30), duration: const Duration(hours:1, minutes:30), source: 'routine'),
      TimelineEvent(id: '${DateTime(now.year, now.month, now.day, 9, 0).millisecondsSinceEpoch}-b', title: '출근 / 업무', start: DateTime(now.year, now.month, now.day, 9, 0), duration: const Duration(hours:4), source: 'calendar'),
      TimelineEvent(id: '${DateTime(now.year, now.month, now.day, 11, 0).millisecondsSinceEpoch}-c', title: '팀 미팅', start: DateTime(now.year, now.month, now.day, 11, 0), duration: const Duration(hours:1), source: 'calendar'),
      TimelineEvent(id: '${DateTime(now.year, now.month, now.day, 20, 0).millisecondsSinceEpoch}-d', title: '사이드 프로젝트 미팅', start: DateTime(now.year, now.month, now.day, 20, 0), duration: const Duration(hours:1), source: 'calendar'),
    ];
    for (var e in timeline) {
      _eventCompletion[e.id] = false;
    }
    notifyListeners();
  }

  /// Generate mock events across the next 7 days to populate the Calendar weekly view.
  Map<String, List<TimelineEvent>> getWeekEvents() {
    final Map<String, List<TimelineEvent>> week = {};
    final now = DateTime.now();
    for (int d = 0; d < 7; d++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
      week[key] = [];
    }

    // Distribute some mock events across the week
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      // 1 fixed calendar event per day at 9:00
      final e1 = TimelineEvent(id: '${DateTime(day.year, day.month, day.day, 9, 0).millisecondsSinceEpoch}-cal', title: '업무 블록', start: DateTime(day.year, day.month, day.day, 9, 0), duration: const Duration(hours: 3), source: 'calendar');
      week['${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}']?.add(e1);
      _eventCompletion[e1.id] = _eventCompletion[e1.id] ?? false;
      // Add occasional side project or study blocks
      if (i % 2 == 0) {
        final e2 = TimelineEvent(id: '${DateTime(day.year, day.month, day.day, 19, 0).millisecondsSinceEpoch}-ai', title: '공부/프로젝트', start: DateTime(day.year, day.month, day.day, 19, 0), duration: const Duration(hours: 1, minutes:30), source: 'ai');
        week['${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}']?.add(e2);
        _eventCompletion[e2.id] = _eventCompletion[e2.id] ?? false;
      }
    }

    return week;
  }

  // Simulate AI generating a new goal
  Future<void> regenerateGoalFromAI() async {
    // in real app: call LLM, get suggestion
    await Future.delayed(const Duration(milliseconds: 400));
    todayGoal = '편입 공부 2시간 확보하기 (AI 제안)';
    notifyListeners();
  }

  // Simulate AI rebalancing timeline when user requests
  Future<void> rebalanceSchedule() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // simple mock: insert a short task at 22:00
    final now = DateTime.now();
    final newEvent = TimelineEvent(id: '${DateTime(now.year, now.month, now.day, 22, 0).millisecondsSinceEpoch}-ai-add', title: 'AI 배치 태스크', start: DateTime(now.year, now.month, now.day, 22, 0), duration: const Duration(hours:1), source: 'ai');
    timeline.add(newEvent);
    _eventCompletion[newEvent.id] = false;
    notifyListeners();
  }

  bool isEventCompleted(String id) {
    return _eventCompletion[id] ?? false;
  }

  void toggleEventComplete(String id) {
    _eventCompletion[id] = !(_eventCompletion[id] ?? false);
    notifyListeners();
  }

  /// Return events for a specific date (combines timeline and week events)
  List<TimelineEvent> getEventsForDate(DateTime date) {
    final List<TimelineEvent> results = [];
    // from timeline
    for (var e in timeline) {
      if (e.start.year == date.year && e.start.month == date.month && e.start.day == date.day) {
        results.add(e);
      }
    }
    // from generated week events (if within next 7 days)
    final week = getWeekEvents();
    final key = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    if (week.containsKey(key)) {
      results.addAll(week[key] ?? []);
    }
    results.sort((a,b) => a.start.compareTo(b.start));
    return results;
  }

  void toggleRoutineComplete(int index) {
    morningRoutines[index].completed = !morningRoutines[index].completed;
    notifyListeners();
  }
}
