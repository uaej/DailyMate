class ActionLog {
  final int? id;
  final int taskId;
  final String actionType; // 'start' or 'complete'
  final DateTime timestamp;
  final int? actualMinutes;

  ActionLog({
    this.id,
    required this.taskId,
    required this.actionType,
    required this.timestamp,
    this.actualMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'action_type': actionType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'actual_minutes': actualMinutes,
    };
  }

  factory ActionLog.fromMap(Map<String, dynamic> map) {
    return ActionLog(
      id: map['id'],
      taskId: map['task_id'],
      actionType: map['action_type'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      actualMinutes: map['actual_minutes'],
    );
  }
}