import 'package:flutter/material.dart';

class SelectProjectScreen extends StatelessWidget {
  const SelectProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Project")),
      body: ListView(
        children: const [
          ListTile(title: Text("Project A")),
          ListTile(title: Text("Project B")),
          ListTile(title: Text("Project C")),
        ],
      ),
    );
  }
}