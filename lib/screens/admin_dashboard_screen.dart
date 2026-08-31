import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'admin_tabs/fleet_management_tab.dart';
import 'admin_tabs/fare_matrix_tab.dart';
import 'admin_tabs/complaints_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    
    // Determine if the screen is wide enough for a side menu
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (adminProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // The main content area
    final Widget bodyContent = IndexedStack(
      index: _selectedIndex,
      children: const [
        FleetManagementTab(),
        FareMatrixTab(),
        ComplaintsTab(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${adminProvider.companyName ?? "Company"} Admin Portal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // If desktop, use a Row with NavigationRail. If mobile/narrow, just show the body.
      body: isDesktop 
        ? Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
                labelType: NavigationRailLabelType.all,
                minExtendedWidth: 200,
                selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
                selectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.directions_bus_outlined),
                    selectedIcon: Icon(Icons.directions_bus),
                    label: Text('Fleet & Shifts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.account_tree_outlined),
                    selectedIcon: Icon(Icons.account_tree),
                    label: Text('Fare Matrix'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.warning_amber_rounded),
                    selectedIcon: Icon(Icons.warning_rounded),
                    label: Text('Complaints'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: bodyContent),
            ],
          )
        : bodyContent,
        
      // If mobile/narrow, show a BottomNavigationBar instead of the side rail
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_outlined), activeIcon: Icon(Icons.directions_bus), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree_outlined), activeIcon: Icon(Icons.account_tree), label: 'Fares'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), activeIcon: Icon(Icons.warning_rounded), label: 'Complaints'),
        ],
      ),
    );
  }
}