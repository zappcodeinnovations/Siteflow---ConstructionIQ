import 'package:flutter/material.dart';

class TimesheetScreen extends StatelessWidget {
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timesheet")),
      body: ListView(
        children: const [
          ListTile(
            title: Text("Monday"),
            subtitle: Text("8 Hours"),
          ),
          ListTile(
            title: Text("Tuesday"),
            subtitle: Text("7 Hours"),
          ),
          ListTile(
            title: Text("Wednesday"),
            subtitle: Text("9 Hours"),
          ),
        ],
      ),
    );
  }
}