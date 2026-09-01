import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';
import '../providers/transit_provider.dart';
import 'bus_cards.dart';
import '../providers/language_provider.dart';

class SmartPlanPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onBusSelected;

  const SmartPlanPanel({
    super.key,
    required this.onClose,
    required this.onBusSelected,
  });

  @override
  State<SmartPlanPanel> createState() => _SmartPlanPanelState();
}

class _SmartPlanPanelState extends State<SmartPlanPanel> {
  bool _showResults = false;
  BusStop? _fromStop;
  BusStop? _toStop;
  TimeOfDay? _arrivalTime;
  List<Bus> _matchingBuses = [];

  void _planTrip(TransitProvider provider, LanguageProvider langProvider) {
    if (_fromStop == null || _toStop == null || _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(langProvider.isBangla ? 'অনুগ্রহ করে কোথা থেকে, কোথায় এবং পৌঁছানোর সময় নির্বাচন করুন।' : 'Please select From, To and arrival time.')),
      );
      return;
    }

    if (_fromStop!.id == _toStop!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(langProvider.isBangla ? 'শুরু এবং গন্তব্য একই স্টপ হতে পারে না।' : 'From and To cannot be the same stop.')),
      );
      return;
    }

    setState(() {
      _matchingBuses = provider.getMatchingBuses(_fromStop!, _toStop!);
      _showResults = true;
    });
  }

  Future<void> _selectArrivalTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selected != null) {
      setState(() {
        _arrivalTime = selected;
        _showResults = false;
      });
    }
  }

  Widget _buildStopDropdown({
    required String title,
    required IconData icon,
    required BusStop? value,
    required List<BusStop> stops,
    required ValueChanged<BusStop?> onChanged,
    required LanguageProvider langProvider,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BusStop>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 8),
              Text(langProvider.t(title)),
            ],
          ),
          items: stops.map((stop) {
            final stopName = langProvider.isBangla ? stop.nameBn : stop.nameEn;
            return DropdownMenuItem<BusStop>(
              value: stop,
              child: Text(stopName, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        // Responsive height constraint to fit smaller screen sizes cleanly
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(langProvider.t('Smart Trip Planner'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStopDropdown(
                title: 'From',
                icon: Icons.my_location,
                value: _fromStop,
                stops: provider.stops,
                onChanged: (value) => setState(() { _fromStop = value; _showResults = false; }),
                langProvider: langProvider,
              ),
              const SizedBox(height: 8),
              _buildStopDropdown(
                title: 'To',
                icon: Icons.location_on,
                value: _toStop,
                stops: provider.stops,
                onChanged: (value) => setState(() { _toStop = value; _showResults = false; }),
                langProvider: langProvider,
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.access_time),
                  title: Text(langProvider.t('Arrive by'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_arrivalTime == null ? langProvider.t('Select arrival time') : _arrivalTime!.format(context)),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  onTap: _selectArrivalTime,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () => _planTrip(provider, langProvider),
                  icon: const Icon(Icons.route),
                  label: Text(langProvider.t('PLAN MY TRIP'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (_showResults) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (_matchingBuses.isEmpty) ...[
                  Builder(
                    builder: (context) {
                      final multiLeg = provider.findMultiLegRoute(_fromStop!, _toStop!);
                      if (multiLeg == null) {
                        return const NoResultCard();
                      }

                      final Bus leg1 = multiLeg['leg1Bus'];
                      final Bus leg2 = multiLeg['leg2Bus'];
                      final BusStop transfer = multiLeg['transferStop'];
                      final transferName = langProvider.isBangla ? transfer.nameBn : transfer.nameEn;
                      final leg1Name = langProvider.isBangla ? leg1.companyBn : leg1.company;
                      final leg2Name = langProvider.isBangla ? leg2.companyBn : leg2.company;
                      final fromName = langProvider.isBangla ? _fromStop!.nameBn : _fromStop!.nameEn;
                      final toName = langProvider.isBangla ? _toStop!.nameBn : _toStop!.nameEn;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.alt_route, color: Colors.orangeAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$fromName ➔ $toName',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text(langProvider.t('1 Transfer Required'), style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            
                            // Leg 1
                            Row(
                              children: [
                                const Icon(Icons.directions_bus, color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 6),
                                Text('${langProvider.t('Leg 1')}: $leg1Name', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${langProvider.t('Board at')} $fromName ➔ ${langProvider.t('Get down at')} $transferName', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.0),
                              child: Icon(Icons.arrow_downward, color: Colors.white54, size: 16),
                            ),

                            // Leg 2
                            Row(
                              children: [
                                const Icon(Icons.directions_bus, color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 6),
                                Text('${langProvider.t('Leg 2')}: $leg2Name', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${langProvider.t('Board at')} $transferName ➔ ${langProvider.t('Arrive at')} $toName', style: const TextStyle(color: Colors.white70, fontSize: 12)),

                            const SizedBox(height: 14),
                            
                            // Action buttons wrapped for safety
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent)),
                                    onPressed: () {
                                      provider.selectBus(leg1);
                                      widget.onBusSelected();
                                    },
                                    icon: const Icon(Icons.map, size: 14, color: Colors.greenAccent),
                                    label: Text(langProvider.t('Track Leg 1'), style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                                    onPressed: () {
                                      provider.selectBus(leg2);
                                      widget.onBusSelected();
                                    },
                                    icon: const Icon(Icons.map, size: 14, color: Colors.orangeAccent),
                                    label: Text(langProvider.t('Track Leg 2'), style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Text(langProvider.t('Smart Recommendations'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  if (provider.getFastestBus(_matchingBuses, _fromStop!, _toStop!) != null) ...[
                    RecommendationCard(
                      title: langProvider.t('FASTEST'),
                      icon: Icons.bolt,
                      iconColor: Colors.orange,
                      bus: provider.getFastestBus(_matchingBuses, _fromStop!, _toStop!)!,
                      fromStop: _fromStop!,
                      toStop: _toStop!,
                      onTap: () {
                        provider.selectBus(provider.getFastestBus(_matchingBuses, _fromStop!, _toStop!));
                        widget.onBusSelected();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (provider.getBestBus(_matchingBuses, _fromStop!, _toStop!) != null &&
                      provider.getBestBus(_matchingBuses, _fromStop!, _toStop!)!.busId != provider.getFastestBus(_matchingBuses, _fromStop!, _toStop!)?.busId) ...[
                    RecommendationCard(
                      title: langProvider.t('BEST OPTION'),
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      bus: provider.getBestBus(_matchingBuses, _fromStop!, _toStop!)!,
                      fromStop: _fromStop!,
                      toStop: _toStop!,
                      onTap: () {
                        provider.selectBus(provider.getBestBus(_matchingBuses, _fromStop!, _toStop!));
                        widget.onBusSelected();
                      },
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}