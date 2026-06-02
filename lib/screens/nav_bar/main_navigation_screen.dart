import 'package:euroside/modules/all_projects/view/all_project_view.dart';
import 'package:euroside/modules/all_projects/provider/all_project_provider.dart';
import 'package:euroside/modules/drawing/view/drawing_list_page.dart';
import 'package:euroside/modules/form/provider/form_provider.dart';
import 'package:euroside/modules/profile/view/profile_view.dart';
import 'package:euroside/modules/profile/provider/profile_provider.dart';
import 'package:euroside/modules/Dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  int _selectedIndex = 0;
  final Set<int> _loadedPages = {0, 1};

  List<Widget> get _pages => const [
    DashboardScreen(),
    AllProjectListPage(),
    DrawingListPage(),
    ProfileView(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
      _loadedPages.add(index);
    });

    if (index == 0) {
      ref.invalidate(formStatusKpiProvider);
      ref.read(formStatusKpiProvider.future);
      ref
          .read(AllprojectControllerProvider.notifier)
          .fetchProjects(force: true);
      ref.read(profileControllerProvider.notifier).getProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List<Widget>.generate(_pages.length, (index) {
          if (_loadedPages.contains(index)) {
            return _pages[index];
          }

          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                _navItem(Icons.grid_view_rounded, "Dashboard", 0),
                _navItem(Icons.calendar_today_outlined, "Projects", 1),
                _navItem(Icons.edit_document, "Drawings", 2),
                _navItem(Icons.person_outline, "Profile", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool selected = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: SizedBox(
            height: double.infinity,
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
        ),
      ),
    );
  }
}
