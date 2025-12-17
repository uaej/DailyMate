class AiDecision {
  final int? id;
  final String triggerEvent; // 'user_message' or 'task_done'
  final String llmInputSummary;
  final String llmOutputJson;
  final String? biasDetected;
  final DateTime createdAt;

  AiDecision({
    this.id,
    required this.triggerEvent,
    required this.llmInputSummary,
    required this.llmOutputJson,
    this.biasDetected,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trigger_event': triggerEvent,
      'llm_input_summary': llmInputSummary,
      'llm_output_json': llmOutputJson,
      'bias_detected': biasDetected,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AiDecision.fromMap(Map<String, dynamic> map) {
    return AiDecision(
      id: map['id'],
      triggerEvent: map['trigger_event'],
      llmInputSummary: map['llm_input_summary'],
      llmOutputJson: map['llm_output_json'],
      biasDetected: map['bias_detected'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}