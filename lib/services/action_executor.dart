import '../services/database_service.dart';
import '../services/llm_service.dart';
import '../models/goal.dart';
import '../models/task.dart';

class ActionExecutor {
  static Future<String> executeActions(List<LLMAction> actions) async {
    final results = <String>[];
    
    for (final action in actions) {
      try {
        final result = await _executeAction(action);
        results.add(result);
      } catch (e) {
        results.add('액션 실행 실패: ${e.toString()}');
      }
    }
    
    return results.join('\n');
  }
  
  static Future<String> _executeAction(LLMAction action) async {
    switch (action.type) {
      case 'create_goal':
        return await _createGoal(action);
      case 'create_task':
        return await _createTask(action);
      case 'mark_completed':
        return await _markCompleted(action);
      case 'update_task':
        return await _updateTask(action);
      case 'delete_task':
        return await _deleteTask(action);
      default:
        return '알 수 없는 액션 타입: ${action.type}';
    }
  }
  
  static Future<String> _createGoal(LLMAction action) async {
    if (action.title == null) {
      throw Exception('목표 제목이 필요합니다');
    }
    
    final goal = Goal(
      title: action.title!,
      createdAt: DateTime.now(),
      status: 'active',
    );
    
    final goalId = await DatabaseService.insertGoal(goal);
    return '새 목표 생성됨: ${action.title} (ID: $goalId)';
  }
  
  static Future<String> _createTask(LLMAction action) async {
    if (action.title == null) {
      throw Exception('태스크 제목이 필요합니다');
    }
    
    // 목표 ID는 optional - 없어도 태스크 생성 가능!
    final task = Task(
      goalId: action.relatedGoalId,  // null 가능
      title: action.title!,
      estimatedMinutes: action.estimatedTime ?? 30,
      status: 'todo',
      createdAt: DateTime.now(),
    );
    
    final taskId = await DatabaseService.insertTask(task);
    
    if (action.relatedGoalId == null) {
      return '✅ ${action.title} 추가했어요';
    } else {
      return '✅ ${action.title} 추가했어요 (목표 ID: ${action.relatedGoalId})';
    }
  }
  
  static Future<String> _markCompleted(LLMAction action) async {
    if (action.taskId == null) {
      throw Exception('완료할 태스크 ID가 필요합니다');
    }
    
    await DatabaseService.updateTaskStatus(action.taskId!, 'done');
    return '태스크 완료 처리됨 (ID: ${action.taskId})';
  }
  
  static Future<String> _updateTask(LLMAction action) async {
    if (action.taskId == null) {
      throw Exception('수정할 태스크 ID가 필요합니다');
    }
    
    // 여기서는 상태만 업데이트하지만, 필요에 따라 제목이나 시간도 수정 가능
    await DatabaseService.updateTaskStatus(action.taskId!, 'in_progress');
    return '태스크 수정됨 (ID: ${action.taskId})';
  }
  
  static Future<String> _deleteTask(LLMAction action) async {
    if (action.taskId == null) {
      throw Exception('삭제할 태스크 ID가 필요합니다');
    }
    
    // DatabaseService에 deleteTask 메서드 추가 필요
    return '태스크 삭제 기능 구현 필요 (ID: ${action.taskId})';
  }
}