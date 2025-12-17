class Task {
  final int? id;
  final String title;
  final String status;
  final int? goalId;
  final int estimatedMinutes;
  final DateTime createdAt;
  final String? goalTitle; // 목표 이름

  Task({
    this.id,
    required this.title,
    this.status = 'todo',
    this.goalId,
    this.estimatedMinutes = 30,
    required this.createdAt,
    this.goalTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'goal_id': goalId,
      'estimated_minutes': estimatedMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      status: map['status'],
      goalId: map['goal_id'],
      estimatedMinutes: map['estimated_minutes'] ?? 30,
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at']) 
          : DateTime.now(),
      goalTitle: map['goal_title'],
    );
  }
}