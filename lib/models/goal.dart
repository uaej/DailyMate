class Goal {
  final int? id;
  final String title;
  final DateTime createdAt;
  final String status; // 'active' or 'done'

  Goal({
    this.id,
    required this.title,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      status: map['status'],
    );
  }
}