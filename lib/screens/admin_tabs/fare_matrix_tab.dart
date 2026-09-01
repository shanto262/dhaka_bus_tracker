import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class FareMatrixTab extends StatefulWidget {
  const FareMatrixTab({super.key});

  @override
  State<FareMatrixTab> createState() => _FareMatrixTabState();
}

class _FareMatrixTabState extends State<FareMatrixTab> {
  String? _selectedOrigin;
  String? _selectedDestination;
  final TextEditingController _standardFareController = TextEditingController();
  final TextEditingController _studentFareController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _standardFareController.dispose();
    _studentFareController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveFare(AdminProvider provider, String docId) async {
    if (_selectedOrigin == null || _selectedDestination == null) return;
    if (_selectedOrigin == _selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin and Destination cannot be the same.')),
      );
      return;
    }

    final standardFare = double.tryParse(_standardFareController.text);
    final studentFare = double.tryParse(_studentFareController.text);

    if (standardFare == null || standardFare <= 0 || studentFare == null || studentFare <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid fare amounts.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final pairKey = '${_selectedOrigin}_${_selectedDestination}';
    
    await provider.updateFare(docId, pairKey, standardFare, studentFare);

    setState(() {
      _isSaving = false;
      _selectedOrigin = null;
      _selectedDestination = null;
      _standardFareController.clear();
      _studentFareController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fares safely updated!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final fareMatrixDoc = provider.fareMatrix;

    if (fareMatrixDoc == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No fare matrix configuration found for this company.', style: TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      );
    }

    final docId = fareMatrixDoc['id'];
    final List<String> stops = List<String>.from(fareMatrixDoc['stops'] ?? []);
    final Map<String, dynamic> matrix = fareMatrixDoc['matrix'] ?? {};

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 900;

          List<Widget> panels = [
            // LEFT PANEL: Fare Editor Form
            Expanded(
              flex: isWideScreen ? 1 : 0,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_road, size: 28),
                            SizedBox(width: 8),
                            Text('Update Fare', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 32),
                        
                        const Text('Origin Stop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedOrigin,
                          hint: const Text('Select Origin'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: stops.map((stop) => DropdownMenuItem(value: stop, child: Text(stop))).toList(),
                          onChanged: (val) => setState(() => _selectedOrigin = val),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text('Destination Stop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedDestination,
                          hint: const Text('Select Destination'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: stops.map((stop) => DropdownMenuItem(value: stop, child: Text(stop))).toList(),
                          onChanged: (val) => setState(() => _selectedDestination = val),
                        ),

                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Standard Fare (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _standardFareController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 20',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.attach_money),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Student Fare (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _studentFareController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 10',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.money_off),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Save Single Fare Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSaving ? null : () => _handleSaveFare(provider, docId),
                            icon: _isSaving 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Icon(Icons.save),
                            label: const Text('SAVE TO MATRIX', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'Note: Student fare = 50% of regular fare only applies when regular fare is 20tk and above.', 
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: isWideScreen ? 24 : 0, height: isWideScreen ? 0 : 24),
            
            // RIGHT PANEL: Active Fare List
            Expanded(
              flex: isWideScreen ? 2 : 0,
              child: SizedBox(
                height: isWideScreen ? null : 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Fares (${matrix.length})', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: matrix.isEmpty
                          ? const Center(child: Text('No fares defined yet. Use the editor to add them.'))
                          : ListView.builder(
                              itemCount: matrix.keys.length,
                              itemBuilder: (context, index) {
                                String key = matrix.keys.elementAt(index);
                                Map<String, dynamic> fares = matrix[key];
                                
                                List<String> pair = key.split('_');
                                String origin = pair.isNotEmpty ? pair[0] : 'Unknown';
                                String destination = pair.length > 1 ? pair[1] : 'Unknown';

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    title: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(origin, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Icon(Icons.arrow_right_alt, color: Colors.grey),
                                        ),
                                        Text(destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text('Standard: ৳${fares['standard']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text('Student: ৳${fares['student']}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.grey),
                                      tooltip: 'Edit Fare',
                                      onPressed: () {
                                        setState(() {
                                          _selectedOrigin = origin;
                                          _selectedDestination = destination;
                                          _standardFareController.text = fares['standard'].toString();
                                          _studentFareController.text = fares['student'].toString();
                                        });
                                      },
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
          ];

          return isWideScreen 
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: panels) 
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: panels);
        },
      ),
    );
  }
}