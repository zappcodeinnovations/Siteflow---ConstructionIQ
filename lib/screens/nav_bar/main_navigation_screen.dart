import 'package:euro_side/modules/form/view/form_screen.dart';
import 'package:euro_side/modules/profile/view/profile_view.dart';
import 'package:euro_side/modules/projects/view/project_list_screen.dart';
import 'package:euro_side/modules/projects/view/project_overview.dart';
import 'package:euro_side/modules/templates/view/template_screen.dart';
import 'package:euro_side/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import '../timesheet/timesheet_screen.dart';
import '../activity/my_activity_screen.dart';
import '../profile/profile_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    ProjectListScreen(),
    FormsScreen(),
    const ProfileView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.grid_view_rounded, "Dashboard", 0),
            _navItem(Icons.calendar_today_outlined, "Projects", 1),
            _navItem(Icons.bar_chart_rounded, "Activity", 2),
            _navItem(Icons.person_outline, "Profile", 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool selected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? const Color.fromARGB(255, 61, 15, 209)
                  : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
