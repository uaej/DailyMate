import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);

    // Calculate streak (mock: based on simple logic for now)
    final streakDays = 5; 

    // Calculate today's stats from 'events'
    // Filter events that are completed (mock logic: assuming past events are done based on time for now, as we don't have completion flag in all events yet)
    final now = DateTime.now();
    final todayEvents = vm.events;
    
    // Simple completion logic: if end time passed, count as done (temporary)
    final completedEventsCount = todayEvents.where((e) => e.start.add(e.duration).isBefore(now)).length;
    final totalEventsCount = todayEvents.length;
    
    // Focus Minutes
    final focusMinutes = todayEvents.fold(0, (sum, e) => sum + e.duration.inMinutes);

    // Routine Stats
    final routines = vm.routines;
    final routineTotal = routines.length;
    final routineCompleted = routines.where((r) => r.completed).length; 
    final routineRate = routineTotal > 0 ? (routineCompleted / routineTotal * 100).toStringAsFixed(0) : '0';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak Card
            Card(
              elevation: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔥 연속 진행', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$streakDays일째', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('목표', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text('30일', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: streakDays / 30,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today's stats
            Text('오늘 현황', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🎯 루틴 달성', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 6),
                            Text('$routineCompleted / $routineTotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: routineTotal > 0 ? routineCompleted / routineTotal : 0,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                              ),
                              Text('$routineRate%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⏱️ 총 예정 시간', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 6),
                              Text('${(focusMinutes ~/ 60)}시간 ${focusMinutes % 60}분', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 50, color: Colors.grey.shade300),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📝 완료 추정', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 6),
                              Text('$completedEventsCount / $totalEventsCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
