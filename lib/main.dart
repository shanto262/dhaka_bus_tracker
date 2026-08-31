import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/transit_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/settings_provider.dart';
import 'utils/db_seeder.dart';
import 'providers/admin_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //await DatabaseSeeder.seedLargeTransitData(forceReset: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransitProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const DhakaBusTrackerApp(),
    ),
  );
}

class DhakaBusTrackerApp extends StatelessWidget {
  const DhakaBusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Dhaka Bus Tracker',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6841), 
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6841),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),

      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Web Routing Configuration
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigationScreen(), // Passenger View
        '/admin': (context) => const AdminAuthGate(),   // Admin Login / Dashboard View
      },
    );
  }
}

// Automatically switches between Login and Dashboard based on Auth status
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          return const AdminDashboardScreen();
        }
        
        return const AdminLoginScreen();
      },
    );
  }
}