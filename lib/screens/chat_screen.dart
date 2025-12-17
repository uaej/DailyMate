import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import '../services/context_service.dart';
import '../services/action_executor.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../viewmodel/home_viewmodel.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;
  final List<LLMAction>? pendingActions;
  bool isActionExecuted;

  ChatMessage({
    required this.text, 
    required this.fromUser, 
    DateTime? time,
    this.pendingActions,
    this.isActionExecuted = false,
  }) : time = time ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isRecording = false;
  DateTime? _recordStart;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), fromUser: true));
    });
    _controller.clear();
    _scrollToEnd();
    _simulateAssistantReply(text);
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordStart = DateTime.now();
      _recordDuration = Duration.zero;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordDuration = DateTime.now().difference(_recordStart!);
      });
    });
  }

  void _stopRecording() {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      final simulatedText = '음성 메시지 (${_recordDuration.inSeconds}s)로 전송';
      _send(simulatedText);
    });
  }

  void _simulateAssistantReply(String userText) async {
    setState(() { _isTyping = true; });
    
    try {
      final contextData = await ContextService.buildContext();
      
      final llmResponse = await LLMService.processUserInput(
        userInput: userText,
        context: contextData,
      );
      
      String responseText = llmResponse.summary;
      
      // 즉시 실행 로직
      if (llmResponse.actions.isNotEmpty) {
        final executionResult = await ActionExecutor.executeActions(llmResponse.actions);
        
        // 데이터 갱신 (즉시 반영)
        if (mounted) {
           Provider.of<HomeViewModel>(context, listen: false).refreshData();
        }

        // 실행 결과 텍스트 추가
        if (executionResult.contains('실패')) {
           responseText += '\n\n⚠️ 일부 작업 실행 실패:\n$executionResult';
        } else if (executionResult.isNotEmpty) {
           // 성공 메시지는 간단하게 요약에 포함되어 있다고 가정하거나, 필요시 추가
           // responseText += '\n\n✅ 실행 완료'; 
        }
      }
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: responseText, fromUser: false));
          _isTyping = false;
        });
        _scrollToEnd();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: '오류가 발생했습니다: ${e.toString()}', fromUser: false));
          _isTyping = false;
        });
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBubble(ChatMessage m) {
    final align = m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = m.fromUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200;
    final textColor = m.fromUser ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Text(m.text, style: TextStyle(color: textColor, height: 1.3)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: Text('${m.time.hour.toString().padLeft(2,'0')}:${m.time.minute.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, idx) {
                if (_isTyping && idx == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Row(children: [
                      Container(width: 8, height:8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width:8),
                      const Text('AI가 입력 중입니다...', style: TextStyle(color: Colors.grey)),
                    ]),
                  );
                }
                final m = _messages[idx];
                return Align(
                  alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: _buildBubble(m),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        hintText: 'AI에게 할 일을 부탁해보세요',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _send(_controller.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
