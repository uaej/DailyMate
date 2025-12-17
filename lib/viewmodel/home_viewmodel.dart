import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/calendar_service.dart';
import '../models/task.dart';
import '../models/goal.dart';

class RoutineItem {
  final String title;
  final Duration duration;
  final DateTime startTime; // 루틴 시작 시간
  bool completed;

  RoutineItem({required this.title, required this.duration, required this.startTime, this.completed = false});
}

class TimelineEvent {
  final String id;
  final String title;
  final DateTime start;
  final Duration duration;
  final String source; // 'calendar', 'routine', 'task', 'ai'
  final bool isAllDay;

  TimelineEvent({
    required this.id, 
    required this.title, 
    required this.start, 
    required this.duration, 
    required this.source,
    this.isAllDay = false
  });
}

class HomeViewModel extends ChangeNotifier {
  // StatsScreen 등에서 참조하는 옛 루틴 변수 (호환성 유지)
  List<RoutineItem> get morningRoutines => routines;
  
  // 실제 관리되는 루틴 리스트
  List<RoutineItem> routines = [
    RoutineItem(title: '기상 및 영양제', duration: const Duration(minutes: 30), startTime: DateTime(2024, 1, 1, 7, 0)),
    RoutineItem(title: '오전 운동', duration: const Duration(minutes: 60), startTime: DateTime(2024, 1, 1, 8, 0)),
  ];

  List<TimelineEvent> events = [];
  List<Task> unscheduledTasks = []; 
  List<Goal> activeGoals = []; // 활성 목표 리스트 추가
  bool isLoading = false;
  
  // AI 연동 필드
  String todayGoal = '로드 중...';
  String todaySummary = '오늘의 요약을 불러오고 있습니다.';

  HomeViewModel() {
    refreshData();
  }

  Future<void> refreshData() async {
    isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      events.clear();
      unscheduledTasks.clear();

      // 1. Google 캘린더 일정
      final calendarEvents = await CalendarService.getTodayEvents();
      for (var e in calendarEvents) {
        final startParts = e['start'].toString().split(':');
        final endParts = e['end'].toString().split(':');
        final startTime = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
        final endTime = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
        
        events.add(TimelineEvent(
          id: 'cal_${e['title']}',
          title: e['title'],
          start: startTime,
          duration: endTime.difference(startTime),
          source: 'calendar'
        ));
      }

      // 2. DB Task
      final tasks = await DatabaseService.getTodayTasks();
      for (var task in tasks) {
        if (task.status != 'done') {
           // Task 모델이 시간 정보가 없다면 일단 미배정 리스트로.
           unscheduledTasks.add(task);
        }
      }

      // 3. 루틴
      for (var routine in routines) {
        final start = DateTime(now.year, now.month, now.day, routine.startTime.hour, routine.startTime.minute);
        events.add(TimelineEvent(
          id: 'routine_${routine.title}',
          title: routine.title,
          start: start,
          duration: routine.duration,
          source: 'routine'
        ));
      }

      // 4. Goals 로드
      activeGoals = await DatabaseService.getActiveGoals();

      // 5. AI 제안 메시지 (테스트용)
      todayGoal = '오늘도 파이팅하세요! (AI)';
      todaySummary = '총 ${events.length}개의 일정과 ${unscheduledTasks.length}개의 할 일이 있습니다.';

      events.sort((a, b) => a.start.compareTo(b.start));

    } catch (e) {
      print('데이터 로드 실패: $e');
    }

    isLoading = false;
    notifyListeners();
  }
  
  // 루틴 추가
  void addRoutine(String title, Duration duration, TimeOfDay time) {
    final now = DateTime.now();
    routines.add(RoutineItem(
      title: title, 
      duration: duration, 
      startTime: DateTime(now.year, now.month, now.day, time.hour, time.minute)
    ));
    refreshData();
  }

  // 스케줄 배치
  void scheduleTask(Task task, DateTime startTime) {
    events.add(TimelineEvent(
      id: 'task_${task.id}',
      title: task.title,
      start: startTime,
      duration: Duration(minutes: task.estimatedMinutes),
      source: 'task'
    ));
    unscheduledTasks.removeWhere((t) => t.id == task.id);
    events.sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
  }

  // --- 기존 호환성 유지 메서드 ---

  List<TimelineEvent> getEventsForDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return events;
    }
    return [];
  }
  
  Map<String, List<TimelineEvent>> getWeekEvents() {
    return {};
  }
  
  bool isEventCompleted(String id) {
    return false;
  }
  
  void toggleEventComplete(String id) {
    // 기능 미구현
  }
  
  Future<void> rebalanceSchedule() async {
    // AI 재조정 - 단순히 새로고침
    await refreshData();
  }
  
  Future<void> regenerateGoalFromAI() async {
    // AI 목표 생성 - 단순히 새로고침
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  void toggleRoutineComplete(int index) {
      if(index < routines.length) {
          routines[index].completed = !routines[index].completed;
          notifyListeners();
      }
  }
}
