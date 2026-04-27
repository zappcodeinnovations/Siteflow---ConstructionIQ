import 'package:flutter/material.dart';

class DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DashboardItem({required this.title, required this.icon, required this.onTap});
}

class ProjectOverviewDashboard extends StatelessWidget {
  final String projectName;
  final String projectDescription;
  final List<DashboardItem> items;

  const ProjectOverviewDashboard({
    super.key,
    required this.projectName,
    required this.projectDescription,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Project Overview"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 PROJECT CARD
              _projectCard(),

              const SizedBox(height: 20),

              /// 🔥 BOOKMARK SECTION
              _bookmarkSection(),

              const SizedBox(height: 20),

              /// 🔥 CREATE ITEM SECTION
              _createItemSection(context),

              const SizedBox(height: 20),

              /// 🔥 GRID DASHBOARD
              _gridSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= PROJECT CARD =================
  Widget _projectCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade200,
            ),
            child: const Icon(Icons.apartment, size: 28),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Project information",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  projectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectDescription,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  /// ================= BOOKMARK =================
  Widget _bookmarkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Bookmarks",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            "You don’t have any bookmarks yet.\nTap bookmark icon to save.",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  /// ================= CREATE ITEM =================
  Widget _createItemSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Create item",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _createTile(Icons.remove_red_eye, "Observation"),
              _divider(),
              _createTile(Icons.checklist, "Inspection"),
              _divider(),
              _createTile(Icons.description, "Daywork sheet"),
              _divider(),
              _createTile(Icons.note, "Notes log"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: const Icon(Icons.add, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _divider() {
    return const Divider(height: 1);
  }

  /// ================= GRID =================
  Widget _gridSection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _DashboardCard(item: item);
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: Colors.blue, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
