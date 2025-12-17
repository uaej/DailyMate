import 'package:flutter/material.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            TodaySummaryCard(),
            GoalCard(),
            RoutineCard(),
            SizedBox(height: 80), // 하단 네비게이션 바 공간
          ],
        ),
      ),
    );
  }
}

