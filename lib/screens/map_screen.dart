import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart'; // Import settings provider
import '../models/bus_stop_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context); // Listen to settings

    final centerLatLng = const LatLng(23.7561, 90.3872); // Dhaka Center

    // Simulated user location (e.g., near Kawran Bazar / Farmgate)
    final userLocation = const LatLng(23.7522, 90.3938);

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.t('Dhaka Bus Tracker'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: 13.5,
                onTap: (_, __) => provider.clearStopSelection(),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.dhaka_bus_tracker',
                ),
                MarkerLayer(
                  markers: [
                    // 1. Show user location ONLY if Location Access is enabled in Settings
                    if (settingsProvider.locationAccess)
                      Marker(
                        point: userLocation,
                        width: 45,
                        height: 45,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.my_location, color: Colors.blue, size: 28),
                          ),
                        ),
                      ),

                    // 2. Bus Stops
                    ...provider.stops.map((stop) => Marker(
                          point: LatLng(stop.lat, stop.lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              provider.selectStop(stop);
                              _showArrivalsBottomSheet(context, stop, provider, langProvider);
                            },
                            child: const Icon(Icons.pin_drop, color: Colors.green, size: 40),
                          ),
                        )),

                    // 3. Selected Bus Marker
                    if (provider.selectedBus != null)
                      Marker(
                        point: LatLng(provider.selectedBus!.currentLat, provider.selectedBus!.currentLng),
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.directions_bus, color: Colors.blueAccent, size: 45),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  void _showArrivalsBottomSheet(
      BuildContext context, BusStop stop, TransitProvider provider, LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final buses = provider.getBusesForSelectedStop();
        final stopName = langProvider.isBangla ? stop.nameBn : stop.nameEn;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
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
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Text(bus.routeTag, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              langProvider.t(bus.isLive ? 'LIVE TRACKING' : 'SCHEDULED'), 
                              style: TextStyle(color: bus.isLive ? Colors.green : Colors.grey)
                            ),
                            trailing: Text('${bus.etaMinutes} min', style: const TextStyle(fontSize: 18, color: Colors.orange)),
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
}