import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/transit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart'; 
import '../models/bus_stop_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _userLocation = const LatLng(23.7522, 90.3938);
  LatLng _centerLatLng = const LatLng(23.7561, 90.3872);
  bool _isGettingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchRealLocation();
  }

  Future<void> _fetchRealLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isGettingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isGettingLocation = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isGettingLocation = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _centerLatLng = _userLocation;
        _isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context); 
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
      body: provider.isLoading || _isGettingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _centerLatLng,
                    initialZoom: 14.0,
                    onTap: (_, __) => provider.clearStopSelection(),
                  ),
                  children: [
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

                    PolylineLayer<Object>(
                      polylines: [
                        if (provider.selectedBus != null)
                          Polyline<Object>(
                            points: provider.getSelectedRouteCoordinates(),
                            color: Colors.blueAccent.withOpacity(0.7),
                            strokeWidth: 4.5,
                            pattern: const StrokePattern.dotted(),
                          ),
                      ],
                    ),

                    MarkerLayer(
                      markers: [
                        if (settingsProvider.locationAccess)
                          Marker(
                            point: _userLocation, 
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

                        ...provider.stops.map((stop) => Marker(
                              point: LatLng(stop.lat, stop.lng),
                              width: 30,
                              height: 30,
                              child: GestureDetector(
                                onTap: () {
                                  provider.selectStop(stop);
                                  _showArrivalsBottomSheet(context, stop, provider, langProvider);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B159), 
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black.withOpacity(0.5), width: 1.5),
                                  ),
                                  child: const Icon(Icons.directions_bus, color: Colors.white, size: 15),
                                ),
                              ),
                            )),

                        if (provider.selectedBus != null)
                          Marker(
                            point: LatLng(
                              provider.selectedBus!.currentLat, 
                              provider.selectedBus!.currentLng,
                            ),
                            width: 46,
                            height: 46,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.shade700,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                if (provider.selectedBus != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Card(
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
                                    langProvider.isBangla
                                        ? provider.selectedBus!.companyBn
                                        : provider.selectedBus!.company,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '${provider.selectedBus!.routeTag} • ${provider.selectedBus!.routeName}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              tooltip: 'Stop Tracking',
                              onPressed: () {
                                provider.clearStopSelection();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
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
}