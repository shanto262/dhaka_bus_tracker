import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';
import '../providers/transit_provider.dart';
import 'bus_cards.dart';

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

  void _planTrip(TransitProvider provider) {
    if (_fromStop == null || _toStop == null || _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select From, To and arrival time.')));
      return;
    }

    if (_fromStop!.id == _toStop!.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('From and To cannot be the same stop.')));
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
              Text(title),
            ],
          ),
          items: stops.map((stop) {
            return DropdownMenuItem<BusStop>(
              value: stop,
              child: Text(stop.nameEn, overflow: TextOverflow.ellipsis),
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

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Expanded(child: Text('Smart Trip Planner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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
              ),
              const SizedBox(height: 8),
              _buildStopDropdown(
                title: 'To',
                icon: Icons.location_on,
                value: _toStop,
                stops: provider.stops,
                onChanged: (value) => setState(() { _toStop = value; _showResults = false; }),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Arrive by', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_arrivalTime == null ? 'Select arrival time' : _arrivalTime!.format(context)),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  onTap: _selectArrivalTime,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () => _planTrip(provider),
                  icon: const Icon(Icons.route),
                  label: const Text('PLAN MY TRIP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (_showResults) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (_matchingBuses.isEmpty)
                  const NoResultCard()
                else ...[
                  const Text('Smart Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  if (provider.getFastestBus(_matchingBuses, _fromStop!, _toStop!) != null) ...[
                    RecommendationCard(
                      title: 'FASTEST',
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
                      title: 'BEST OPTION',
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