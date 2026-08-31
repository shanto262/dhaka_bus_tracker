import 'package:flutter/material.dart';
import '../models/bus_stop_model.dart';
import '../providers/transit_provider.dart';
import '../providers/language_provider.dart';

void showArrivalsBottomSheet({
  required BuildContext context,
  required BusStop stop,
  required TransitProvider provider,
  required LanguageProvider langProvider,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final buses = provider.getBusesForSelectedStop();
      final stopName = langProvider.isBangla ? stop.nameBn : stop.nameEn;

      return Container(
        padding: const EdgeInsets.all(16),
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$stopName ${langProvider.t('Upcoming Arrivals')}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: buses.isEmpty
                  ? Center(child: Text(langProvider.t('No buses currently scheduled.')))
                  : ListView.builder(
                      itemCount: buses.length,
                      itemBuilder: (context, index) {
                        final bus = buses[index];
                        final companyName = langProvider.isBangla ? bus.companyBn : bus.company;
                        final actualEta = provider.getDynamicEta(bus, stop);

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bus.routeTag,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
                            ),
                          ),
                          title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            langProvider.t(bus.isLive ? 'LIVE TRACKING' : 'SCHEDULED'),
                            style: TextStyle(color: bus.isLive ? Colors.green : Colors.grey),
                          ),
                          trailing: Text(
                            '$actualEta min',
                            style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            provider.selectBus(bus);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}