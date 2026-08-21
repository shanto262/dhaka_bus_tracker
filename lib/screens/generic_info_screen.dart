import 'package:flutter/material.dart';

class GenericInfoScreen extends StatelessWidget {
  final String title;
  
  const GenericInfoScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '$title Content',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen will be connected to the API in Phase 4.',
              style: TextStyle(color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}