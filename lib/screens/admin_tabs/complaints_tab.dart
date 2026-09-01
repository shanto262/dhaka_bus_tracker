import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/admin_provider.dart';

class ComplaintsTab extends StatefulWidget {
  const ComplaintsTab({super.key});

  @override
  State<ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<ComplaintsTab> {
  Map<String, dynamic>? _selectedComplaint;
  String? _selectedStaffIdToPin;
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _getStaffName(String? staffId, List<Map<String, dynamic>> staffList) {
    if (staffId == null || staffId.isEmpty) return 'Unknown';
    final staff = staffList.firstWhere((s) => s['id'] == staffId, orElse: () => {'name': 'Unknown'});
    return staff['name'];
  }

  Future<void> _handleResolve(AdminProvider provider) async {
    if (_selectedComplaint == null || _selectedStaffIdToPin == null) return;
    setState(() => _isProcessing = true);
    await provider.resolveAndPinComplaint(_selectedComplaint!['id'], _selectedStaffIdToPin!, _noteController.text);
    setState(() {
      _isProcessing = false;
      _selectedComplaint = null;
      _selectedStaffIdToPin = null;
      _noteController.clear();
    });
  }

  Future<void> _handleDismiss(AdminProvider provider) async {
    if (_selectedComplaint == null) return;
    setState(() => _isProcessing = true);
    await provider.dismissComplaint(_selectedComplaint!['id'], _noteController.text.isEmpty ? 'Dismissed by admin' : _noteController.text);
    setState(() {
      _isProcessing = false;
      _selectedComplaint = null;
      _selectedStaffIdToPin = null;
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final complaints = provider.complaints;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 900;

          List<Widget> panels = [
            // LEFT PANEL: Complaint List
            Expanded(
              flex: isWideScreen ? 1 : 0,
              child: SizedBox(
                height: isWideScreen ? null : 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Active Tickets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: complaints.isEmpty
                          ? const Center(child: Text('No complaints found.'))
                          : ListView.builder(
                              itemCount: complaints.length,
                              itemBuilder: (context, index) {
                                final complaint = complaints[index];
                                final isSelected = _selectedComplaint?['id'] == complaint['id'];
                                final status = complaint['status'] ?? 'pending';

                                return Card(
                                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                                  elevation: isSelected ? 0 : 2,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Icon(
                                      status == 'pending' ? Icons.warning_amber_rounded : Icons.check_circle,
                                      color: status == 'pending' ? Colors.orange : Colors.green,
                                    ),
                                    title: Text(complaint['complaint_type'] ?? 'Unknown Issue', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Bus: ${complaint['bus_id']}'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      setState(() {
                                        _selectedComplaint = complaint;
                                        _noteController.clear();
                                        
                                        final attribution = provider.getAttributionForComplaint(complaint);
                                        if (attribution != null) {
                                          if (complaint['complaint_type'] == 'Overcharging Fare') {
                                            _selectedStaffIdToPin = attribution['conductorId'];
                                          } else if (complaint['complaint_type'] == 'Reckless Driving') {
                                            _selectedStaffIdToPin = attribution['driverId'];
                                          } else {
                                            _selectedStaffIdToPin = null;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(width: isWideScreen ? 24 : 0, height: isWideScreen ? 0 : 24),
            
            // RIGHT PANEL: Triaging Workspace
            Expanded(
              flex: isWideScreen ? 2 : 1,
              child: _selectedComplaint == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Select a ticket to review', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                        ],
                      ),
                    )
                  : _buildTriagingWorkspace(provider, isWideScreen),
            ),
          ];

          return isWideScreen 
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: panels) 
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: panels);
        },
      ),
    );
  }

  Widget _buildTriagingWorkspace(AdminProvider provider, bool isWideScreen) {
    final complaint = _selectedComplaint!;
    final attribution = provider.getAttributionForComplaint(complaint);
    final hasPhoto = complaint['photo_base64'] != null && complaint['photo_base64'].toString().isNotEmpty;
    final isResolved = complaint['status'] != 'pending';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Text('Ticket #${complaint['id'].toString().substring(0, 6).toUpperCase()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isResolved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                    isResolved ? 'RESOLVED' : 'NEEDS ACTION',
                    style: TextStyle(color: isResolved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const Divider(height: 32),
            
            // Complaint Details & Photo (Visible for both Pending and Resolved tickets)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isWideScreen ? 350 : double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Issue', complaint['complaint_type']),
                      const SizedBox(height: 12),
                      _buildDetailRow('Bus ID', complaint['bus_id']),
                      const SizedBox(height: 12),
                      const Text('Passenger Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(complaint['details'] ?? 'No details provided.', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                if (hasPhoto)
                  Container(
                    width: isWideScreen ? 200 : double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(complaint['photo_base64'])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
              ],
            ),
            const Divider(height: 48),

            // Attribution Engine & Actions (Only for Pending)
            if (!isResolved) ...[
              const Text('Attribution Engine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Based on the time of report, these staff were on duty (${attribution?['shift'] ?? 'Unknown Shift'}):', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isWideScreen ? 300 : double.infinity,
                    child: _buildStaffSelectionCard(
                      role: 'Driver',
                      staffId: attribution?['driverId'],
                      staffName: attribution?['driverName'] ?? 'Unknown',
                      icon: Icons.engineering,
                    ),
                  ),
                  SizedBox(
                    width: isWideScreen ? 300 : double.infinity,
                    child: _buildStaffSelectionCard(
                      role: 'Conductor',
                      staffId: attribution?['conductorId'],
                      staffName: attribution?['conductorName'] ?? 'Unknown',
                      icon: Icons.receipt_long,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Admin Resolution Note (Internal)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 16,
                runSpacing: 16,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => _handleDismiss(provider),
                    child: const Text('DISMISS TICKET', style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    onPressed: (_isProcessing || _selectedStaffIdToPin == null || _selectedStaffIdToPin!.isEmpty) ? null : () => _handleResolve(provider),
                    icon: _isProcessing 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.gavel),
                    label: const Text('PIN TO STAFF & RESOLVE'),
                  ),
                ],
              )
            ] else ...[
              // Resolved State View
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resolution Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 8),
                    Text('Pinned to: ${_getStaffName(complaint['pinnedStaffId'], provider.staff)}'),
                    const SizedBox(height: 4),
                    Text('Note: ${complaint['resolutionNote'] ?? 'None'}'),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildStaffSelectionCard({required String role, required String? staffId, required String staffName, required IconData icon}) {
    final isSelected = _selectedStaffIdToPin == staffId && staffId != null && staffId.isNotEmpty;
    
    return InkWell(
      onTap: (staffId == null || staffId.isEmpty) ? null : () {
        setState(() => _selectedStaffIdToPin = staffId);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.orange.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(staffName, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.orange : Colors.black), overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}