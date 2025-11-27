import 'package:flutter/material.dart';
// imports kept minimal; widgets use Provider where needed
import '../widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DailyMate'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings))
        ],
      ),
      body: Column(
        children: [
          const TodaySummaryCard(),
          const GoalCard(),
          const RoutineCard(),
          Expanded(child: SingleChildScrollView(child: Column(children: const [TimelineView()]))),
        ],
      ),
      bottomNavigationBar: const SizedBox(height: 72, child: AIInputBar()),
      floatingActionButton: const FloatingAIButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
