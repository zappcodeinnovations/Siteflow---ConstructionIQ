import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("John Doe"),
            subtitle: Text("Site Engineer"),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text("john@email.com"),
          ),
          ListTile(
            leading: Icon(Icons.phone),
            title: Text("+91 9999999999"),
          ),
        ],
      ),
    );
  }
}