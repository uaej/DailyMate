import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';

enum CalendarView { day, week, month }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarView _view = CalendarView.day; // default to day view
  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _prevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Widget _buildSegment() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Day'),
          selected: _view == CalendarView.day,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          onSelected: (_) => setState(() => _view = CalendarView.day),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Week'),
          selected: _view == CalendarView.week,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          onSelected: (_) => setState(() => _view = CalendarView.week),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Month'),
          selected: _view == CalendarView.month,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          onSelected: (_) => setState(() => _view = CalendarView.month),
        ),
      ],
    );
  }

  Widget _dayView(HomeViewModel vm) {
    final events = vm.getEventsForDate(_selectedDate);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: _prevDay, icon: const Icon(Icons.chevron_left)),
              Column(
                children: [
                  Text('${_selectedDate.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${_selectedDate.month}/${_selectedDate.day}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(onPressed: _nextDay, icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('이 날짜에는 일정이 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  itemBuilder: (context, idx) {
                    final e = events[idx];
                    final end = e.start.add(e.duration);
                    final timeRange = '${e.start.hour.toString().padLeft(2,'0')}:${e.start.minute.toString().padLeft(2,'0')} - ${end.hour.toString().padLeft(2,'0')}:${end.minute.toString().padLeft(2,'0')}';
                    final completed = vm.isEventCompleted(e.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Checkbox(value: completed, onChanged: (_) { vm.toggleEventComplete(e.id); }),
                        title: Text(e.title, style: TextStyle(decoration: completed ? TextDecoration.lineThrough : TextDecoration.none)),
                        subtitle: Text('$timeRange · ${e.source}'),
                        trailing: Container(
                          width: 8,
                          height: 40,
                          decoration: BoxDecoration(color: e.source == 'calendar' ? Colors.blueAccent : Colors.greenAccent, borderRadius: BorderRadius.circular(4)),
                        ),
                        onTap: () { vm.toggleEventComplete(e.id); },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _weekView(HomeViewModel vm) {
    final week = vm.getWeekEvents();
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
          final events = week[key] ?? [];
          return SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][day.weekday % 7]} ${day.month}/${day.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...events.map((e) {
                  final completed = vm.isEventCompleted(e.id);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: completed ? Colors.grey.shade200 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        Checkbox(value: completed, onChanged: (_) { vm.toggleEventComplete(e.id); }),
                        Expanded(child: Text(e.title, style: TextStyle(decoration: completed ? TextDecoration.lineThrough : TextDecoration.none))),
                        const SizedBox(width: 6),
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: e.source == 'calendar' ? Colors.blueAccent : Colors.green, shape: BoxShape.circle)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _monthView(HomeViewModel vm) {
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = firstDay.weekday % 7; // 0=Sun

    // build grid of 6 rows x 7 cols
    final cells = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, d);
      final events = vm.getEventsForDate(date);
      cells.add(GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
            _view = CalendarView.day;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$d', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (events.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('${events.length} events', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ]
            ],
          ),
        ),
      ));
    }

    // fill remaining cells to make full grid
    while (cells.length % 7 != 0) cells.add(const SizedBox());

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () { setState(() { _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1); }); }, icon: const Icon(Icons.chevron_left)),
              Text('${_displayedMonth.year}년 ${_displayedMonth.month}월', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () { setState(() { _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1); }); }, icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
            childAspectRatio: 1.1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<HomeViewModel>(context);
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildSegment(),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _view == CalendarView.day ? _dayView(vm) : (_view == CalendarView.week ? _weekView(vm) : _monthView(vm)),
            ),
          ),
        ],
      ),
    );
  }
}
