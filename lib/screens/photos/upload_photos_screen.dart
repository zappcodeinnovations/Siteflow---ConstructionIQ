import 'package:flutter/material.dart';

class UploadPhotosScreen extends StatelessWidget {
  const UploadPhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Photos")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: const Text("Upload Photo"),
        ),
      ),
    );
  }
}