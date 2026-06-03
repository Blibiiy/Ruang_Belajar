import 'package:flutter/material.dart';
import '../../home/presentation/home_page.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../focus/presentation/focus_page.dart';
import '../../stats/presentation/stats_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    CalendarPage(),
    FocusPage(),
    StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.4),
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
              BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Focus'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
            ],
          ),
        ),
      ),
    );
  }
}