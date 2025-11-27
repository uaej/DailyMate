import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text('Calendar - 주/월 단위 일정 뷰', style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
