import 'package:flutter/material.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<ActivityHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text("Coming Soon....",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ),
    );
  }
}