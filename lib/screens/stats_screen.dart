import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);

    // Calculate streak (mock: based on completed routines today)
    final completedRoutines = vm.morningRoutines.where((r) => r.completed).length;
    final streakDays = completedRoutines > 0 ? 12 : 5; // mock streak value; could be from persistent storage

    // Calculate this week's completed tasks
    final weekEvents = vm.getWeekEvents();
    int completedThisWeek = 0;
    for (var dayEvents in weekEvents.values) {
      for (var e in dayEvents) {
        if (vm.isEventCompleted(e.id)) completedThisWeek++;
      }
    }
    final totalWeekEvents = weekEvents.values.fold(0, (sum, list) => sum + list.length);

    // Calculate morning routine completion rate today
    final routineTotal = vm.morningRoutines.length;
    final routineCompleted = vm.morningRoutines.where((r) => r.completed).length;
    final routineRate = routineTotal > 0 ? (routineCompleted / routineTotal * 100).toStringAsFixed(0) : '0';

    // Today's focus time (mock: from timeline durations)
    final todayEvents = vm.getEventsForDate(DateTime.now());
    final focusMinutes = todayEvents.fold(0, (sum, e) => sum + e.duration.inMinutes);

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
                        Text('${streakDays}일째', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        minHeight: 8,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Weekly completed tasks
            Text('이번 주', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('완료한 태스크', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text('$completedThisWeek / $totalWeekEvents', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(width: 1, height: 60, color: Colors.grey.shade300),
                    Column(
                      children: [
                        Text('완료율', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text('${((completedThisWeek / (totalWeekEvents > 0 ? totalWeekEvents : 1)) * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today's stats
            Text('오늘', style: Theme.of(context).textTheme.titleMedium),
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
                            Text('🎯 아침 루틴', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 6),
                            Text('$routineCompleted / $routineTotal ($routineRate%)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              Text('⏱️ 집중 시간', style: Theme.of(context).textTheme.bodyMedium),
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
                              Text('📝 예정 태스크', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 6),
                              Text('${todayEvents.length}개', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
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

            // Motivation message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💪 오늘의 다짐', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    streakDays < 7 ? '루틴을 꾸준히 지켜보세요. 작은 습관이 모여 큰 변화를 만듭니다!' : streakDays < 30 ? '멋진 진행 중입니다! 계속 이 감각을 유지해보세요.' : '30일 연속 달성 가능합니다. 거의 다 왔어요!',
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
