import 'dart:async';

import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;
  ChatMessage({required this.text, required this.fromUser, DateTime? time}) : time = time ?? DateTime.now();
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
    // NOTE: This is a mocked recording flow. For real voice input,
    // integrate a speech-to-text plugin (e.g., speech_to_text) and handle permissions.
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
    // Simulate STT result after short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      final simulatedText = '음성 메시지 (${_recordDuration.inSeconds}s)로 전송';
      _send(simulatedText);
    });
  }

  void _simulateAssistantReply(String userText) {
    setState(() { _isTyping = true; });
    // simple mocked reply: echo + suggestion
    Future.delayed(const Duration(milliseconds: 800), () {
      final reply = "알겠어요! '${userText.length > 40 ? userText.substring(0,40) + '...' : userText}' 에 대해 도와드릴게요.\n오늘 일정에 맞춰 제안할게요.";
      setState(() {
        _messages.add(ChatMessage(text: reply, fromUser: false));
        _isTyping = false;
      });
      _scrollToEnd();
    });
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
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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
                        hintText: 'AI에게 질문하거나 일정 변경을 요청하세요',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.redAccent : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: _isRecording ? Colors.white : Colors.black54),
                        ),
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () => _send(_controller.text),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
