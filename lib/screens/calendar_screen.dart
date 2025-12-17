import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).refreshData();
    });
  }

  void _addRoutineDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반복 루틴 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '루틴 이름'),
            ),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: '소요 시간 (분)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('시작 시간: '),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      selectedTime = time;
                      (context as Element).markNeedsBuild();
                    }
                  },
                  child: Text(selectedTime.format(context)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Provider.of<HomeViewModel>(context, listen: false).addRoutine(
                  titleController.text,
                  Duration(minutes: int.tryParse(durationController.text) ?? 30),
                  selectedTime,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);
    
    // 타임라인 범위 (06:00 ~ 24:00)
    final startHour = 6;
    final endHour = 24;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. 헤더 (날짜 및 컨트롤)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        vm.isLoading ? '동기화 중...' : '오늘의 일정',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: vm.refreshData,
                    tooltip: '캘린더/태스크 동기화',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_task),
                    onPressed: _addRoutineDialog,
                    tooltip: '루틴 추가',
                  ),
                ],
              ),
            ),
            
            // 2. 타임라인 뷰
            Expanded(
              child: vm.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 시간축
                      SizedBox(
                        width: 50,
                        child: ListView.builder(
                          itemCount: endHour - startHour + 1,
                          itemBuilder: (context, index) {
                            final hour = startHour + index;
                            return SizedBox(
                              height: 60, // 1시간 높이
                              child: Center(
                                child: Text(
                                  '$hour:00', 
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // 이벤트 영역
                      Expanded(
                        child: SingleChildScrollView(
                          child: Stack(
                            children: [
                              // 그리드 라인
                              Column(
                                children: List.generate(endHour - startHour + 1, (index) {
                                  return Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                    ),
                                  );
                                }),
                              ),
                              
                              // 이벤트 블록들
                              ...vm.events.map((event) {
                                // 시간 위치 계산
                                final eventHour = event.start.hour;
                                final eventMinute = event.start.minute;
                                
                                if (eventHour < startHour || eventHour >= endHour) return const SizedBox();
                                
                                final topOffset = (eventHour - startHour) * 60.0 + eventMinute;
                                final height = event.duration.inMinutes.toDouble();
                                
                                Color eventColor;
                                switch (event.source) {
                                  case 'calendar': eventColor = Colors.blue.shade100; break;
                                  case 'routine': eventColor = Colors.orange.shade100; break;
                                  case 'task': eventColor = Colors.green.shade100; break;
                                  default: eventColor = Colors.grey.shade100;
                                }

                                return Positioned(
                                  top: topOffset,
                                  left: 4,
                                  right: 4,
                                  height: height > 20 ? height : 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: eventColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: eventColor.withOpacity(0.5)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (height > 40)
                                          Text(
                                            '${event.duration.inMinutes}분',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
            
            // 3. 하단 배정되지 않은 할 일 (시간 배정 대기)
            if (vm.unscheduledTasks.isNotEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('시간 미정 할 일 (${vm.unscheduledTasks.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: vm.unscheduledTasks.length,
                        itemBuilder: (context, index) {
                          final task = vm.unscheduledTasks[index];
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8, bottom: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${task.estimatedMinutes}분', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    InkWell(
                                      onTap: () {
                                        // 현재 시간으로 배정 (임시 - 나중엔 드래그 앤 드롭)
                                        final now = DateTime.now();
                                        // 다음 정각으로 배정
                                        final nextHour = now.hour + 1;
                                        vm.scheduleTask(task, DateTime(now.year, now.month, now.day, nextHour, 0));
                                      },
                                      child: const Icon(Icons.add_circle, size: 20, color: Colors.blue),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
