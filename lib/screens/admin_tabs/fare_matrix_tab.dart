import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class FareMatrixTab extends StatefulWidget {
  const FareMatrixTab({super.key});

  @override
  State<FareMatrixTab> createState() => _FareMatrixTabState();
}

class _FareMatrixTabState extends State<FareMatrixTab> {
  // Keeps track of any fares the admin edits before they hit publish
  final Map<String, double> _editedFares = {};
  bool _isPublishing = false;

  void _publishChanges(AdminProvider provider, String routeId) async {
    if (_editedFares.isEmpty) return;

    setState(() => _isPublishing = true);

    // Loop through all edited cells and update Firestore
    for (var entry in _editedFares.entries) {
      await provider.updateFare(routeId, entry.key, entry.value);
    }

    setState(() {
      _editedFares.clear();
      _isPublishing = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fare chart successfully published to the live network!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final fareData = provider.fareMatrix;

    if (fareData == null) {
      return const Center(
        child: Text('No fare matrix configuration found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    final String routeId = fareData['id'];
    final List<String> stops = List<String>.from(fareData['stops'] ?? []);
    final Map<String, dynamic> currentMatrix = fareData['matrix'] ?? {};

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Fare Matrix',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Student fares are automatically calculated as exactly 50% of the standard fare.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _editedFares.isEmpty ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: _editedFares.isEmpty || _isPublishing
                    ? null
                    : () => _publishChanges(provider, routeId),
                icon: _isPublishing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload),
                label: Text(_isPublishing ? 'PUBLISHING...' : 'PUBLISH FARE CHART'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // ==========================================
          // THE TRIANGULAR DATA GRID
          // ==========================================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              // Two ScrollViews allow scrolling horizontally and vertically if the route is very long
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    columnSpacing: 24,
                    columns: [
                      const DataColumn(label: Text('Origin \\ Destination')),
                      ...stops.map((stop) => DataColumn(label: Text(stop))),
                    ],
                    rows: List.generate(stops.length, (rowIndex) {
                      final rowStop = stops[rowIndex];

                      return DataRow(
                        cells: [
                          // First cell in the row is the origin stop name
                          DataCell(Text(rowStop, style: const TextStyle(fontWeight: FontWeight.bold))),
                          
                          // Generate cells for each destination column
                          ...List.generate(stops.length, (colIndex) {
                            final colStop = stops[colIndex];

                            // Block out the diagonal (same stop) and bottom triangle
                            if (colIndex <= rowIndex) {
                              return DataCell(Container(color: Colors.grey.shade100));
                            }

                            final stopPairKey = '${rowStop}_$colStop';
                            final cellData = currentMatrix[stopPairKey] ?? {'standard': 0.0, 'student': 0.0};
                            
                            // If we have an unsaved edit, show that instead of the database value
                            final standardFare = _editedFares[stopPairKey] ?? (cellData['standard'] as num).toDouble();
                            final studentFare = _editedFares.containsKey(stopPairKey) 
                                ? (standardFare / 2).ceilToDouble() 
                                : (cellData['student'] as num).toDouble();

                            return DataCell(
                              _buildFareInput(
                                standardFare: standardFare,
                                studentFare: studentFare,
                                onChanged: (val) {
                                  setState(() {
                                    _editedFares[stopPairKey] = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Visual widget for the individual grid cells
  Widget _buildFareInput({
    required double standardFare,
    required double studentFare,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: TextFormField(
              initialValue: standardFare.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              decoration: const InputDecoration(
                prefixText: '৳ ',
                border: UnderlineInputBorder(),
                contentPadding: EdgeInsets.only(bottom: 12),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Std: ৳${studentFare.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}