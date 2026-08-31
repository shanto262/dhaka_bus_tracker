import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class FleetManagementTab extends StatelessWidget {
  const FleetManagementTab({super.key});

  // Helper function to find a staff member's name by their ID
  String _getStaffName(String staffId, List<Map<String, dynamic>> staffList) {
    final staff = staffList.firstWhere(
      (s) => s['id'] == staffId,
      orElse: () => {'name': 'Unassigned'},
    );
    return staff['name'];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final buses = provider.buses;
    final staffList = provider.staff;

    if (buses.isEmpty) {
      return const Center(
        child: Text('No buses found for this company.', style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fleet & Shift Roster',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage active buses and staff assignments.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400, // Adapts nicely to desktop/tablet screens
                mainAxisExtent: 320,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final bus = buses[index];
                return _buildBusCard(context, bus, staffList);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, Map<String, dynamic> bus, List<Map<String, dynamic>> staffList) {
    // Safely extract shift data, falling back to empty maps if not present
    final shifts = bus['shifts'] as Map<String, dynamic>? ?? {};
    final morning = shifts['morning'] as Map<String, dynamic>? ?? {};
    final evening = shifts['evening'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: License Plate & Route Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bus['licensePlate'] ?? 'Unknown Plate',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bus['routeTag'] ?? 'N/A',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Morning Shift
            _buildShiftRow(
              context: context,
              shiftName: 'Morning Shift',
              time: '06:00 - 14:00',
              driverId: morning['driverId'],
              conductorId: morning['conductorId'],
              staffList: staffList,
            ),
            
            const SizedBox(height: 16),
            
            // Evening Shift
            _buildShiftRow(
              context: context,
              shiftName: 'Evening Shift',
              time: '14:00 - 22:00',
              driverId: evening['driverId'],
              conductorId: evening['conductorId'],
              staffList: staffList,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftRow({
    required BuildContext context,
    required String shiftName,
    required String time,
    required String? driverId,
    required String? conductorId,
    required List<Map<String, dynamic>> staffList,
  }) {
    final driverName = driverId != null ? _getStaffName(driverId, staffList) : 'Unassigned';
    final conductorName = conductorId != null ? _getStaffName(conductorId, staffList) : 'Unassigned';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(shiftName.contains('Morning') ? Icons.wb_sunny : Icons.nightlight_round, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Text(shiftName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.engineering, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Driver: $driverName', style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.receipt_long, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Conductor: $conductorName', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}