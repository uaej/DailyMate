import '../services/database_service.dart';
import '../services/calendar_service.dart';
import '../models/goal.dart';
import '../models/task.dart';

class ContextService {
  static Future<Map<String, dynamic>> buildContext() async {
    final now = DateTime.now();
    
    // DB에서 현재 상태 가져오기
    final goals = await DatabaseService.getActiveGoals();
    final tasks = await DatabaseService.getTodayTasks();
    
    // Google Calendar에서 오늘 일정 가져오기
    final calendar = await CalendarService.getTodayEvents();
    
    return {
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'current_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'goals': goals.map((g) => {
        'id': g.id,
        'title': g.title,
        'status': g.status,
        'created_at': g.createdAt.toIso8601String(),
      }).toList(),
      'tasks': tasks.map((t) => {
        'id': t.id,
        'goal_id': t.goalId,
        'title': t.title,
        'status': t.status,
        'estimated_minutes': t.estimatedMinutes,
        'created_at': t.createdAt.toIso8601String(),
      }).toList(),
      'calendar': calendar,
    };
  }
}