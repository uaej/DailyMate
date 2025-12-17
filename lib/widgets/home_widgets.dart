import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/goal.dart';
import '../models/task.dart';
import 'package:dailymate/viewmodel/home_viewmodel.dart';
import 'package:provider/provider.dart';

class TodaySummaryCard extends StatefulWidget {
  const TodaySummaryCard({super.key});

  @override
  State<TodaySummaryCard> createState() => _TodaySummaryCardState();
}

class _TodaySummaryCardState extends State<TodaySummaryCard> {
  List<Task> tasks = [];
  
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }
  
  _loadTasks() async {
    final loadedTasks = await DatabaseService.getTodayTasks();
    setState(() {
      tasks = loadedTasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ViewModel 구독
    final vm = context.watch<HomeViewModel>();
    final completedCount = vm.events.where((e) => e.source == 'task' && vm.isEventCompleted(e.id)).length + 
                           vm.routines.where((r) => r.completed).length; // 임시 계산
    // HomeViewModel에 completedTasksCount 등이 없으므로, ViewModel 데이터를 직접 활용하거나
    // 여기서는 Local State 대신 ViewModel을 써야 하지만, 
    // 기존 코드는 Local State 'tasks'를 썼음.
    // '화면 전체적으로 새로고침' 요구사항 -> ViewModel 사용.
    
    // 단순화를 위해 ViewModel의 events만 사용하거나 unscheduledTasks 사용.
    // 정확한 통계를 위해 ViewModel에 computed property가 있으면 좋지만 여기선 간단히 텍스트만 바꿈.
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘 요약', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height:6),
                // 상세 카운트는 HomeViewModel 로직에 의존
                Text(vm.todaySummary, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            // 버튼 제거됨 (자동 갱신)
          ],
        ),
      ),
    );
  }
}

class GoalCard extends StatefulWidget {
  const GoalCard({super.key});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  
  _editGoal() async {
    final vm = Provider.of<HomeViewModel>(context, listen: false);
    final goals = vm.activeGoals;
    final currentGoal = goals.isNotEmpty ? goals.first : null;
    final controller = TextEditingController(text: currentGoal?.title ?? '');
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentGoal == null ? '새 목표 추가' : '목표 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '목표'),
          autofocus: true,
        ),
        actions: [
          if (currentGoal != null)
            TextButton(
              onPressed: () => Navigator.pop(context, {'action': 'delete'}),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {'action': 'save', 'title': controller.text}),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      if (result['action'] == 'delete' && currentGoal != null) {
        // 목표 삭제
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('목표 삭제'),
            content: Text('${currentGoal.title}을(를) 정말 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          await DatabaseService.deleteGoal(currentGoal.id!);
          if (mounted) vm.refreshData();
        }
      } else if (result['action'] == 'save') {
        final title = result['title'];
        if (title != null && title.isNotEmpty) {
          if (currentGoal == null) {
            // 새 목표 추가
            await DatabaseService.insertGoal(Goal(
              title: title,
              createdAt: DateTime.now(),
              status: 'active',
            ));
          } else {
            // 기존 목표 수정
            await DatabaseService.updateGoalTitle(currentGoal.id!, title);
          }
          if (mounted) vm.refreshData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final goals = vm.activeGoals;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '내 목표 (${goals.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _editGoal, // Add new goal
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ),
              ],
            ),
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '아직 설정된 목표가 없습니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: goals.map((goal) => 
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // 간단한 삭제 다이얼로그
                              showDialog(context: context, builder: (_) => AlertDialog(
                                title: const Text('목표 삭제'),
                                content: Text("'${goal.title}' 목표를 삭제할까요?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                                  TextButton(onPressed: () { 
                                     Navigator.pop(context);
                                     DatabaseService.deleteGoal(goal.id!);
                                     vm.refreshData();
                                  }, child: const Text('삭제', style: TextStyle(color: Colors.red))),
                                ],
                              ));
                            }, 
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          )
                        ],
                      ),
                    )
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RoutineCard extends StatefulWidget {
  const RoutineCard({super.key});

  @override
  State<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<RoutineCard> {
  List<Task> tasks = [];
  
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }
  
  _loadTasks() async {
    final loadedTasks = await DatabaseService.getTodayTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    setState(() {
      // todo 상태만 표시 + 하루 지난 완료 항목 제외
      tasks = loadedTasks.where((task) {
        if (task.status == 'todo') return true;
        
        // 완료 항목은 오늘 완료한 것만 표시
        if (task.status == 'done') {
          final taskDate = DateTime(
            task.createdAt.year,
            task.createdAt.month,
            task.createdAt.day,
          );
          return taskDate.isAtSameMomentAs(today);
        }
        
        return false;
      }).toList();
    });
  }
  
  _toggleTask(Task task) async {
    final newStatus = task.status == 'done' ? 'todo' : 'done';
    await DatabaseService.updateTaskStatus(task.id!, newStatus);
    _loadTasks();
  }
  
  _editTask(Task task) async {
    final controller = TextEditingController(text: task.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('작업 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '작업 제목'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await DatabaseService.updateTaskTitle(task.id!, result);
      _loadTasks();
    }
  }
  
  _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('작업 삭제'),
        content: Text('${task.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await DatabaseService.deleteTask(task.id!);
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoTasks = tasks.where((t) => t.status == 'todo').toList();
    final doneTasks = tasks.where((t) => t.status == 'done').toList();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('오늘 할 일', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadTasks,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('할 일이 없습니다. 채팅에서 추가해보세요!'),
              )
            else ...[
              // Todo 작업들
              ...todoTasks.map((task) => Dismissible(
                key: Key('task_${task.id}'),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteTask(task),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: false,
                    onChanged: (_) => _toggleTask(task),
                  ),
                  title: Text(task.title),
                  subtitle: task.goalTitle != null 
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.goalTitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      )
                    : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${task.estimatedMinutes}분'),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _editTask(task),
                      ),
                    ],
                  ),
                ),
              )),
              
              // 오늘 완료한 작업들
              if (doneTasks.isNotEmpty) ...[
                const Divider(),
                Text('완료 (오늘)', 
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                ...doneTasks.map((task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: true,
                    onChanged: (_) => _toggleTask(task),
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Text('${task.estimatedMinutes}분'),
                )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  List<Task> tasks = [];
  
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }
  
  _loadTasks() async {
    final loadedTasks = await DatabaseService.getTodayTasks();
    setState(() {
      tasks = loadedTasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('작업 목록', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:8),
          if (tasks.isEmpty)
            const Card(
              child: ListTile(
                title: Text('작업이 없습니다'),
                subtitle: Text('채팅에서 새 작업을 추가해보세요'),
              ),
            )
          else
            ...tasks.map((task) => Card(
              child: ListTile(
                leading: Icon(
                  task.status == 'done' ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: task.status == 'done' ? Colors.green : Colors.grey,
                ),
                title: Text(task.title),
                subtitle: Text('예상 시간: ${task.estimatedMinutes}분'),
                trailing: Text(task.status == 'done' ? '완료' : '대기'),
              ),
            )),
        ],
      ),
    );
  }
}

class AIInputBar extends StatelessWidget {
  const AIInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    final vm = Provider.of<HomeViewModel>(context, listen: false);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: '오늘 뭐 도와줄까?', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))), contentPadding: EdgeInsets.symmetric(horizontal:12, vertical:8)),
                onSubmitted: (text) async {
                  // For now treat any submission as rebalance request
                  await vm.rebalanceSchedule();
                  controller.clear();
                },
              ),
            ),
            const SizedBox(width:8),
            IconButton(onPressed: () async { await vm.rebalanceSchedule(); }, icon: const Icon(Icons.send_rounded))
          ],
        ),
      ),
    );
  }
}

class FloatingAIButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const FloatingAIButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed ?? () {
        // default fallback: push ChatScreen as a new route
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Center(child: Text('AI Chat (placeholder)'))));
      },
      child: const Icon(Icons.smart_toy_rounded),
    );
  }
}
