import 'package:flutter/foundation.dart';

class RoutineItem {
  final String title;
  final Duration duration;
  bool completed;

  RoutineItem({required this.title, required this.duration, this.completed = false});
}

class TimelineEvent {
  final String title;
  final DateTime start;
  final Duration duration;
  final String source; // e.g., 'calendar', 'routine', 'ai'

  TimelineEvent({required this.title, required this.start, required this.duration, required this.source});
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

  HomeViewModel() {
    _generateMockTimeline();
  }

  void _generateMockTimeline() {
    final now = DateTime.now();
    timeline = [
      TimelineEvent(title: '아침 루틴', start: DateTime(now.year, now.month, now.day, 7, 30), duration: const Duration(hours:1, minutes:30), source: 'routine'),
      TimelineEvent(title: '출근 / 업무', start: DateTime(now.year, now.month, now.day, 9, 0), duration: const Duration(hours:4), source: 'calendar'),
      TimelineEvent(title: '팀 미팅', start: DateTime(now.year, now.month, now.day, 11, 0), duration: const Duration(hours:1), source: 'calendar'),
      TimelineEvent(title: '사이드 프로젝트 미팅', start: DateTime(now.year, now.month, now.day, 20, 0), duration: const Duration(hours:1), source: 'calendar'),
    ];
    notifyListeners();
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
    timeline.add(TimelineEvent(title: 'AI 배치 태스크', start: DateTime(now.year, now.month, now.day, 22, 0), duration: const Duration(hours:1), source: 'ai'));
    notifyListeners();
  }

  void toggleRoutineComplete(int index) {
    morningRoutines[index].completed = !morningRoutines[index].completed;
    notifyListeners();
  }
}
