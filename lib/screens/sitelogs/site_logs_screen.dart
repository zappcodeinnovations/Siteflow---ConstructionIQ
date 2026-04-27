import 'package:flutter/material.dart';

class SiteLogsScreen extends StatelessWidget {
  const SiteLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Site Logs")),
      body: ListView(
        children: const [
          ListTile(
            title: Text("Industrial Hub B14"),
            subtitle: Text("Foundation Pouring"),
          ),
          ListTile(
            title: Text("London Terminal C"),
            subtitle: Text("Steel Inspection"),
          ),
        ],
      ),
    );
  }
}