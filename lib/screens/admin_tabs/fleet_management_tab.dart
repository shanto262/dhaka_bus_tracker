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

  // Helper to show the assigned staff categorized by shift
  void _showBusShiftDetails(BuildContext context, Map<String, dynamic> bus, List<Map<String, dynamic>> allStaff) {
    final shifts = bus['shifts'] as Map<String, dynamic>? ?? {};
    final morning = shifts['morning'] as Map<String, dynamic>? ?? {};
    final evening = shifts['evening'] as Map<String, dynamic>? ?? {};

    Map<String, dynamic> getStaffById(String? id) {
      if (id == null || id.isEmpty) return {};
      return allStaff.firstWhere(
        (s) => s['id'] == id,
        orElse: () => {},
      );
    }

    final morningDriver = getStaffById(morning['driverId']);
    final morningConductor = getStaffById(morning['conductorId']);
    final eveningDriver = getStaffById(evening['driverId']);
    final eveningConductor = getStaffById(evening['conductorId']);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.directions_bus, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bus['routeTag'] ?? 'Bus Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(bus['licensePlate'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  // MORNING SHIFT
                  _buildShiftSection(
                    context: context,
                    title: 'Morning Shift',
                    timeWindow: morning['timeWindow'] ?? '06:00 - 14:00',
                    icon: Icons.wb_sunny_outlined,
                    iconColor: Colors.orange,
                    driver: morningDriver,
                    conductor: morningConductor,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // EVENING SHIFT
                  _buildShiftSection(
                    context: context,
                    title: 'Evening Shift',
                    timeWindow: evening['timeWindow'] ?? '14:00 - 22:00',
                    icon: Icons.nights_stay_outlined,
                    iconColor: Colors.indigo,
                    driver: eveningDriver,
                    conductor: eveningConductor,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShiftSection({
    required BuildContext context,
    required String title,
    required String timeWindow,
    required IconData icon,
    required Color iconColor,
    required Map<String, dynamic> driver,
    required Map<String, dynamic> conductor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timeWindow,
                style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildStaffTile(
          role: 'Driver',
          name: driver['name'] ?? 'Not Assigned',
          phone: driver['phone'] ?? 'N/A',
          isDriver: true,
        ),
        const SizedBox(height: 6),
        _buildStaffTile(
          role: 'Conductor',
          name: conductor['name'] ?? 'Not Assigned',
          phone: conductor['phone'] ?? 'N/A',
          isDriver: false,
        ),
      ],
    );
  }

  Widget _buildStaffTile({
    required String role,
    required String name,
    required String phone,
    required bool isDriver,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isDriver ? Icons.engineering : Icons.receipt_long,
            size: 18,
            color: isDriver ? Colors.blue : Colors.purple,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$role: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Phone: $phone', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          bool isWideScreen = constraints.maxWidth > 900;

          List<Widget> panels = [
            // LEFT PANEL: Active Fleet
            Expanded(
              flex: isWideScreen ? 1 : 0,
              child: SizedBox(
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
                              onTap: () => _showBusShiftDetails(context, bus, provider.staff),
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
                                  borderRadius: BorderRadius.circular(12),
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

            // Spacing
            SizedBox(width: isWideScreen ? 24 : 0, height: isWideScreen ? 0 : 24),

            // RIGHT PANEL: Staff Directory & Strikes
            Expanded(
              flex: isWideScreen ? 2 : 1,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                                  final String rawId = staff['id']?.toString() ?? 'N/A';
                                  final String displayId = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
                                  final String assignedBus = staff['busId'] ?? 'Unassigned';

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isDriver ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                                      child: Icon(
                                        isDriver ? Icons.engineering : Icons.receipt_long,
                                        color: isDriver ? Colors.blue : Colors.purple,
                                      ),
                                    ),
                                    title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('ID: $displayId • Phone: ${staff['phone'] ?? 'N/A'}'),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.directions_bus, size: 14, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Bus: $assignedBus',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: strikes > 0 ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: strikes > 0 ? Colors.red : Colors.transparent),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            strikes > 0 ? Icons.warning_rounded : Icons.check_circle,
                                            color: strikes > 0 ? Colors.red : Colors.grey,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$strikes Strikes',
                                            style: TextStyle(
                                              color: strikes > 0 ? Colors.red : Colors.grey.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
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

          return isWideScreen
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: panels)
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: panels);
        },
      ),
    );
  }
}