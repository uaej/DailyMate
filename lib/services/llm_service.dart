import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LLMService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  static Future<LLMResponse> processUserInput({
    required String userInput,
    required Map<String, dynamic> context,
  }) async {
    try {
      final prompt = _buildPrompt(userInput, context);
      final response = await _callLLM(prompt);
      return _parseResponse(response);
    } catch (e) {
      return LLMResponse(
        intent: 'error',
        summary: 'AI 처리 중 오류가 발생했습니다: ${e.toString()}',
        actions: [],
      );
    }
  }

  static String _buildPrompt(String userInput, Map<String, dynamic> context) {
    return '''
당신은 DailyMate AI 비서입니다. 행동심리학과 인지과학 원칙에 기반하여 사용자를 돕습니다.

=== 핵심 원칙 (과학적 근거) ===
1. **진입장벽 제거**: 목표가 없어도 태스크 추가 가능
2. **인지 부하 이론**: 큰 목표는 작은 하위 과제로 분해 (Sweller, 1988)
3. **자기효능감**: 단계적 달성으로 "할 수 있다"는 인식 형성 (Bandura, 1997)
4. **실행 의도**: 언제/어디서/어떻게까지 구체화 (Gollwitzer, 1999)
5. **자기조절**: 진행 점검과 재조정 피드백 제공

=== 현재 상황 ===
날짜: ${context['date']}
현재 시각: ${context['current_time']}

활성 목표:
${_formatGoals(context['goals'])}

오늘의 태스크:
${_formatTasks(context['tasks'])}

오늘의 캘린더 일정:
${_formatCalendar(context['calendar'])}

=== 사용자 입력 ===
"$userInput"

=== 요청 유형 판별 ===
**조회**: "알려줘", "보여줘", "뭐야" → query
**생성**: "추가", "만들어", "해야 해" → create_task
**완료**: "완료", "끝냈어" → mark_completed
**재조정**: "못했어", "늦어져", "변경" → reschedule

=== 큰 태스크 분해 전략 (인지 부하 이론) ===
다음 조건 시 분해 제안:
- 추상적: "공부", "준비", "만들기"
- 90분 이상 예상
- 복수 단계: "포트폴리오", "이력서"

**분해 시 원칙**:
1. 각 하위 과제는 30-60분 단위
2. 첫 과제는 가장 쉬운 것 (자기효능감 ↑)
3. 구체적 행동 동사 사용

=== 실행 의도 강화 (Gollwitzer) ===
태스크 생성 시 가능하면 제안:
- **언제**: "오늘 저녁 7시", "내일 아침"
- **어디서**: "도서관", "집 책상"
- **어떻게**: "노트북으로 초안 작성"

단, 정보가 없으면 강요하지 말 것.

=== 피드백과 재조정 (자기조절 이론) ===
진행 중 태스크가 있으면:
- 진행 상황 확인 제안
- 어려움 감지 시 조정 제안
- 완료 시 긍정적 강화

=== 응답 예시 ===

[예시 1: 간단한 태스크 + 실행 의도]
입력: "보고서 써야 해"
{
  "intent": "create_task",
  "summary": "알겠어요! '보고서 작성' 추가했어요. 언제 시작할까요? 오늘 저녁이나 내일 아침 중 편한 시간 있으면 알려주세요.",
  "actions": [{
    "type": "create_task",
    "title": "보고서 작성",
    "estimated_time": 60
  }]
}

[예시 2: 큰 태스크 분해 + 자동 추가]
입력: "포트폴리오 만들어야 해"
{
  "intent": "suggest_breakdown",
  "summary": "포트폴리오는 한 번에 하기엔 큰 일이에요. 부담 없이 시작할 수 있게 3단계로 나눠서 태스크에 추가해 드렸어요! 🚀\\n\\n1. 기존 프로젝트 폴더 정리 (30분)\\n2. 대표 프로젝트 1개 선정 (20분)\\n3. 프로젝트 설명 작성 (60분)\\n\\n가볍게 '폴더 정리'부터 시작해볼까요?",
  "actions": [
    {
      "type": "create_task",
      "title": "기존 프로젝트 폴더 정리",
      "estimated_time": 30
    },
    {
      "type": "create_task",
      "title": "대표 프로젝트 1개 선정",
      "estimated_time": 20
    },
    {
      "type": "create_task",
      "title": "프로젝트 설명 작성",
      "estimated_time": 60
    }
  ]
}

[예시 3: 진행 점검 (자기조절)]
입력: "오늘 뭐 했지?"
{
  "intent": "query",
  "summary": "오늘 '보고서 작성' 완료했네요! 👏 내일은 '프로젝트 정리'가 남아있어요. 오늘처럼 잘 하실 수 있을 거예요!",
  "actions": []
}

[예시 4: 재조정 제안]
입력: "보고서 못 끝냈어"
{
  "intent": "reschedule",
  "summary": "괜찮아요! 어떤 부분이 어려웠나요? 시간을 더 주거나 작은 단계로 나눠볼 수도 있어요.",
  "actions": []
}

=== 나쁜 예시 (절대 금지) ===
❌ "목표가 없어 추가할 수 없습니다"
❌ "더 구체적으로 말해주세요" (강요)
❌ 분해 제안 시 actions를 비워두지 마세요 (반드시 분해된 태스크를 create_task로 포함)
❌ 컨텍스트에 없는 데이터 언급

반드시 아래 JSON 형식으로만 응답하세요. 마크다운 코드 블록 없이 순수 JSON만:
{
  "intent": "query|create_goal|create_task|mark_completed|suggest_breakdown|reschedule",
  "summary": "친근하고 과학적인 응답 (자기효능감 ↑, 실행 의도 강화)",
  "actions": [
    {
      "type": "create_task|create_goal|mark_completed|update_task",
      "title": "구체적 행동 동사 사용",
      "estimated_time": 30-60분_권장,
      "related_goal_id": null,
      "task_id": null
    }
  ]
}
''';
  }

  static String _formatGoals(List<dynamic> goals) {
    if (goals.isEmpty) return '- 없음';
    return goals.map((g) => '- ${g['title']} (ID: ${g['id']}, 상태: ${g['status']})').join('\n');
  }

  static String _formatTasks(List<dynamic> tasks) {
    if (tasks.isEmpty) return '- 없음';
    return tasks.map((t) => '- ${t['title']} (ID: ${t['id']}, 목표ID: ${t['goal_id']}, 예상시간: ${t['estimated_minutes']}분)').join('\n');
  }

  static String _formatCalendar(List<dynamic> calendar) {
    if (calendar.isEmpty) return '- 없음';
    return calendar.map((e) => '- ${e['title']} (${e['start']} - ${e['end']})').join('\n');
  }

  static Future<String> _callLLM(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('Gemini API 키가 설정되지 않았습니다');
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': prompt}]
        }]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('LLM API 호출 실패: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  }

  static LLMResponse _parseResponse(String response) {
    try {
      // 마크다운 코드 블록 제거 (```json ... ``` 형식)
      String cleanedResponse = response.trim();
      
      // ```json 또는 ``` 로 시작하는 경우 제거
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      
      // 마지막 ``` 제거
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      
      cleanedResponse = cleanedResponse.trim();
      
      final jsonResponse = jsonDecode(cleanedResponse);
      return LLMResponse.fromJson(jsonResponse);
    } catch (e) {
      print('JSON 파싱 에러: $e');
      print('원본 응답: $response');
      return LLMResponse(
        intent: 'error',
        summary: 'AI 응답을 해석할 수 없습니다',
        actions: [],
      );
    }
  }
}

class LLMResponse {
  final String intent;
  final String summary;
  final List<LLMAction> actions;

  LLMResponse({
    required this.intent,
    required this.summary,
    required this.actions,
  });

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      intent: json['intent'] ?? 'unknown',
      summary: json['summary'] ?? '',
      actions: (json['actions'] as List?)
          ?.map((action) => LLMAction.fromJson(action))
          .toList() ?? [],
    );
  }
}

class LLMAction {
  final String type;
  final String? title;
  final int? estimatedTime;
  final int? relatedGoalId;
  final int? taskId;

  LLMAction({
    required this.type,
    this.title,
    this.estimatedTime,
    this.relatedGoalId,
    this.taskId,
  });

  factory LLMAction.fromJson(Map<String, dynamic> json) {
    return LLMAction(
      type: json['type'] ?? '',
      title: json['title'],
      estimatedTime: json['estimated_time'],
      relatedGoalId: json['related_goal_id'],
      taskId: json['task_id'],
    );
  }
}