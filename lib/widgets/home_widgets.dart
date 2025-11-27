import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';

class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);
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
                Text(vm.todaySummary, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            IconButton(
              onPressed: () async { await vm.regenerateGoalFromAI(); },
              icon: const Icon(Icons.refresh_rounded),
            )
          ],
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🎯 오늘의 목표', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () async { await vm.regenerateGoalFromAI(); }, child: const Text('AI 제안'))
              ],
            ),
            const SizedBox(height:6),
            Text(vm.todayGoal, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class RoutineCard extends StatelessWidget {
  const RoutineCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('아침 루틴', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height:8),
            ...List.generate(vm.morningRoutines.length, (i) {
              final r = vm.morningRoutines[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(value: r.completed, onChanged: (_) => vm.toggleRoutineComplete(i)),
                title: Text(r.title),
                trailing: Text('${r.duration.inMinutes}분'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  String _timeLabel(DateTime dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘 일정', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:8),
          ...vm.timeline.map((e) => Card(
            child: ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text(_timeLabel(e.start), style: const TextStyle(fontSize:12)), const SizedBox(height:4), Text('${e.duration.inHours}h', style: const TextStyle(fontSize:11))],
              ),
              title: Text(e.title),
              subtitle: Text(e.source),
            ),
          )).toList()
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
  const FloatingAIButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // navigate to Chat tab or show dialog; here we'll show a simple dialog placeholder
        showModalBottomSheet(context: context, builder: (_) {
          return SizedBox(height: 400, child: Center(child: Text('AI Chat (placeholder)')));
        });
      },
      child: const Icon(Icons.smart_toy_rounded),
    );
  }
}
