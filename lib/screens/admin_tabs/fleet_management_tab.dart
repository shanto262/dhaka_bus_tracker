import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class FleetManagementTab extends StatefulWidget {
  const FleetManagementTab({super.key});

  @override
  State<FleetManagementTab> createState() => _FleetManagementTabState();
}

class _FleetManagementTabState extends State<FleetManagementTab> {
  String _staffFilter = 'All'; 

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final buses = provider.buses;
    
    // Filter and sort staff (highest strikes first)
    List<Map<String, dynamic>> staffList = provider.staff.where((s) {
      if (_staffFilter == 'All') return true;
      return s['role'].toString().toLowerCase() == _staffFilter.toLowerCase();
    }).toList();
    
    staffList.sort((a, b) {
      int countA = a['complaintsCount'] ?? 0;
      int countB = b['complaintsCount'] ?? 0;
      return countB.compareTo(countA); // Descending
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Check if we have enough space for side-by-side (Desktop/Web)
          bool isWideScreen = constraints.maxWidth > 900;

          List<Widget> panels = [
            // LEFT PANEL: Active Fleet
            Expanded(
              flex: isWideScreen ? 1 : 0, 
              child: SizedBox(
                // Give it a fixed height when stacked vertically, otherwise let it expand
                height: isWideScreen ? null : 350, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, size: 28),
                        const SizedBox(width: 8),
                        Text('Active Fleet (${buses.length})', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: buses.length,
                        itemBuilder: (context, index) {
                          final bus = buses[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(Icons.directions_bus, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(bus['routeTag'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Text(bus['licensePlate'] ?? ''),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: const Text('ON ROUTE', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Add spacing between the panels based on layout
            SizedBox(width: isWideScreen ? 24 : 0, height: isWideScreen ? 0 : 24),
            
            // RIGHT PANEL: Staff Directory & Strikes
            Expanded(
              flex: isWideScreen ? 2 : 1, // Takes 2/3 width on wide screens, 100% height when stacked
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIX: Changed this from a Row to a Wrap so it won't overflow
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          const Text('Staff Directory & Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'All', label: Text('All')),
                              ButtonSegment(value: 'Driver', label: Text('Drivers')),
                              ButtonSegment(value: 'Conductor', label: Text('Conductors')),
                            ],
                            selected: {_staffFilter},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() => _staffFilter = newSelection.first);
                            },
                          )
                        ],
                      ),
                      const Divider(height: 32),
                      
                      Expanded(
                        child: staffList.isEmpty
                            ? const Center(child: Text('No staff members found.'))
                            : ListView.separated(
                                itemCount: staffList.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final staff = staffList[index];
                                  final role = staff['role'].toString().toUpperCase();
                                  final strikes = staff['complaintsCount'] ?? 0;
                                  final isDriver = role == 'DRIVER';

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isDriver ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                                      child: Icon(
                                        isDriver ? Icons.engineering : Icons.receipt_long,
                                        color: isDriver ? Colors.blue : Colors.purple,
                                      ),
                                    ),
                                    title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('ID: ${staff['id'].toString().substring(0, 8)} • Phone: ${staff['phone']}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: strikes > 0 ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: strikes > 0 ? Colors.red : Colors.transparent)
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            strikes > 0 ? Icons.warning_rounded : Icons.check_circle, 
                                            color: strikes > 0 ? Colors.red : Colors.grey, 
                                            size: 16
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$strikes Strikes', 
                                            style: TextStyle(
                                              color: strikes > 0 ? Colors.red : Colors.grey.shade700, 
                                              fontWeight: FontWeight.bold
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];

          // Return a Row for Web/Desktop, or a Column for Mobile/Narrow Windows
          return isWideScreen 
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: panels) 
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: panels);
        },
      ),
    );
  }
}