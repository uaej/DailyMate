import 'package:flutter/material.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Content-only Home screen (no Scaffold) so RootScreen can host the global Scaffold
    return SafeArea(
      child: Column(
        children: const [
          TodaySummaryCard(),
          GoalCard(),
          RoutineCard(),
          Expanded(child: SingleChildScrollView(child: TimelineView())),
          // AIInputBar intentionally included inside the page content so it appears above bottom nav
          // Note: do not include global FAB here; RootScreen or other pages may provide their own.
          SizedBox(height: 8),
          // AIInputBar placed outside of Expanded to keep it visible
        ],
      ),
    );
  }
}

