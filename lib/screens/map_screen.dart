import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart'; 
import '../models/bus_stop_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context); 
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final centerLatLng = const LatLng(23.7561, 90.3872); 
    final userLocation = const LatLng(23.7522, 90.3938);

    // We use the light Voyager map as the base because it has high-contrast roads.
    // Notice the '@2x' at the end of the URL for crisper, retina-quality rendering!
    final baseTileLayer = TileLayer(
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.example.dhaka_bus_tracker',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.t('Dhaka Bus Tracker'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
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
                // The Magic Inversion Trick for Dark Mode
                isDarkMode
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          -1,  0,  0, 0, 255,
                           0, -1,  0, 0, 255,
                           0,  0, -1, 0, 255,
                           0,  0,  0, 1,   0,
                        ]),
                        child: baseTileLayer,
                      )
                    : baseTileLayer,

                MarkerLayer(
                  markers: [
                    // 1. User Location
                    if (settingsProvider.locationAccess)
                      Marker(
                        point: userLocation,
                        width: 45,
                        height: 45,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1),
                          ),
                          child: const Center(
                            child: Icon(Icons.my_location, color: Colors.blueAccent, size: 24),
                          ),
                        ),
                      ),

                    // 2. Bus Stops
                    ...provider.stops.map((stop) => Marker(
                          point: LatLng(stop.lat, stop.lng),
                          width: 32,
                          height: 32,
                          child: GestureDetector(
                            onTap: () {
                              provider.selectStop(stop);
                              _showArrivalsBottomSheet(context, stop, provider, langProvider);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B159), 
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black.withOpacity(0.5), width: 2),
                              ),
                              child: const Icon(Icons.directions_bus, color: Colors.white, size: 16),
                            ),
                          ),
                        )),

                    // 3. Selected Bus Marker
                    if (provider.selectedBus != null)
                      Marker(
                        point: LatLng(provider.selectedBus!.currentLat, provider.selectedBus!.currentLng),
                        width: 48,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))
                            ]
                          ),
                          child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                        ),
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
                              child: Text(bus.routeTag, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900)),
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