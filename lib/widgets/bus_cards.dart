import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus_model.dart';
import '../models/bus_stop_model.dart';
import '../providers/transit_provider.dart';
import '../providers/language_provider.dart';

// --- Selected Bus Card ---
class SelectedBusCard extends StatelessWidget {
  const SelectedBusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    
    if (provider.selectedBus == null) return const SizedBox.shrink();
    
    final bus = provider.selectedBus!;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.deepOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    langProvider.isBangla ? bus.companyBn : bus.company,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${bus.routeTag} • ${bus.routeName}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              tooltip: 'Stop Tracking',
              onPressed: () => provider.clearStopSelection(),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Recommendation Card ---
class RecommendationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Bus bus;
  final BusStop fromStop;
  final BusStop toStop;
  final VoidCallback onTap;

  const RecommendationCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bus,
    required this.fromStop,
    required this.toStop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context, listen: false);
    final travelTime = provider.estimatedTravelTime(bus, fromStop, toStop);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 19),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              Text(bus.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route, size: 14),
                      const SizedBox(width: 3),
                      Text(bus.routeTag, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14),
                      const SizedBox(width: 3),
                      Text('$travelTime min', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_outlined, size: 14),
                      const SizedBox(width: 3),
                      Text('${bus.standardFare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: bus.isLive ? Colors.green : Colors.orange),
                  const SizedBox(width: 5),
                  Text(bus.isLive ? 'Live tracking' : 'Scheduled', style: const TextStyle(fontSize: 11)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- No Result Card ---
class NoResultCard extends StatelessWidget {
  const NoResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off, color: Colors.orange, size: 30),
          SizedBox(height: 6),
          Text('No direct bus found', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 3),
          Text('Try another starting point or destination.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}