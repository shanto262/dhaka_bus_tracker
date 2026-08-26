import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'map_screen.dart';
import 'ai_assistant_screen.dart';
import 'complaint_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    AiAssistantScreen(),
    ComplaintScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: langProvider.t('Map')),
          BottomNavigationBarItem(icon: const Icon(Icons.support_agent), label: langProvider.t('AI Assistant')),
          BottomNavigationBarItem(icon: const Icon(Icons.report_problem), label: langProvider.t('Complaint')),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: langProvider.t('Settings')),
        ],
      ),
    );
  }
}