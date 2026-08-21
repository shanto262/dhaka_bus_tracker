import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'providers/transit_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Trigger the bus upload script! (Commented out because data is already in Firestore)
  // await uploadInitialBuses();

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

Future<void> uploadInitialBuses() async {
  final firestore = FirebaseFirestore.instance;
  
  // Check if already uploaded
  final snapshot = await firestore.collection('buses').get();
  if (snapshot.docs.isNotEmpty) {
    debugPrint('Buses already seeded!');
    return;
  }

  debugPrint('Fetching real stop IDs to link buses...');
  
  // 1. Get the real auto-generated IDs of your stops
  final stopsSnapshot = await firestore.collection('bus_stops').get();
  Map<String, String> dbIds = {};
  for (var doc in stopsSnapshot.docs) {
    dbIds[doc.data()['nameEn']] = doc.id;
  }

  // 2. Upload buses using those REAL IDs
  final List<Map<String, dynamic>> buses = [
    {
      'company': 'Bikash Paribahan',
      'companyBn': 'বিকাশ পরিবহন',
      'routeTag': 'A-101',
      'routeName': 'Mirpur 10 ➔ Motijheel',
      'licensePlate': 'Dhaka Metro-Ba 11-4521',
      'standardFare': 35.0,
      'studentFare': 18.0,
      'nextStopId': dbIds['Farmgate'] ?? '',
      'etaMinutes': 4,
      'isLive': true,
      'currentLat': 23.7580,
      'currentLng': 90.3890,
      // Dynamically linking the real Firestore IDs
      'stopIds': [dbIds['Mirpur 10'], dbIds['Farmgate'], dbIds['Shahbagh'], dbIds['Motijheel']].whereType<String>().toList(),
    },
    {
      'company': 'Uttara Express',
      'companyBn': 'উত্তরা এক্সপ্রেস',
      'routeTag': 'U-205',
      'routeName': 'Uttara ➔ Shahbagh',
      'licensePlate': 'Dhaka Metro-Cha 14-8890',
      'standardFare': 40.0,
      'studentFare': 20.0,
      'nextStopId': dbIds['Mohakhali'] ?? '',
      'etaMinutes': 8,
      'isLive': true,
      'currentLat': 23.8650,
      'currentLng': 90.3980,
      'stopIds': [dbIds['Uttara'], dbIds['Mohakhali'], dbIds['Farmgate'], dbIds['Shahbagh']].whereType<String>().toList(),
    }
  ];

  for (var bus in buses) {
    await firestore.collection('buses').add(bus);
  }

  debugPrint('✅ All buses uploaded to Firestore successfully!');
}