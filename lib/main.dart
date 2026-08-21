import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transit_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransitProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const DhakaBusTrackerApp(),
    ),
  );
}

class DhakaBusTrackerApp extends StatelessWidget {
  const DhakaBusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Dhaka Bus Tracker',
      debugShowCheckedModeBanner: false,
      
      // Standard Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6841), 
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),

      // New Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6841),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),

      // Tell Flutter which theme to use based on the provider
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: const MainNavigationScreen(),
    );
  }
}