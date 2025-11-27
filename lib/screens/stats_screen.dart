import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text('Stats - 루틴/목표/집중시간 통계', style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
