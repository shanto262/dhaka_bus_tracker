import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/transit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart'; 
import '../models/bus_stop_model.dart';
import '../widgets/smart_plan_panel.dart';
import '../widgets/bus_cards.dart';
import '../widgets/arrivals_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showSmartPlan = false;
  LatLng _userLocation = const LatLng(23.7522, 90.3938); // Fallback location (Kawran Bazar area)
  LatLng _centerLatLng = const LatLng(23.7561, 90.3872);
  bool _isGettingLocation = true;
  bool _hasValidLocation = false; // Tracks whether permission was granted

  final MapController _mapController = MapController();
  TransitProvider? _transitProvider;
  String? _lastTrackedBusId;

  // AI Route Argument Variables
  String? _targetBusName;
  String? _targetOrigin;
  String? _targetDestination;
  bool _hasInitializedFromArgs = false;

  @override
  void initState() {
    super.initState();
    _fetchRealLocation();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transitProvider = Provider.of<TransitProvider>(context, listen: false);
      _transitProvider!.addListener(_onProviderUpdated);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedFromArgs) {
      _hasInitializedFromArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _targetBusName = args['busName'];
        _targetOrigin = args['origin'];
        _targetDestination = args['destination'];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_targetBusName != null && _transitProvider != null) {
            final matchingBus = _transitProvider!.buses.firstWhere(
              (b) => _targetBusName!.contains(b.company) || _targetBusName!.contains(b.routeTag),
              orElse: () => _transitProvider!.buses.first,
            );
            _transitProvider!.selectBus(matchingBus);
          }
        });
      }
    }
  }

  void _onProviderUpdated() {
    final bus = _transitProvider!.selectedBus;
    
    if (bus != null && bus.busId != _lastTrackedBusId) {
      _lastTrackedBusId = bus.busId;
      _mapController.move(LatLng(bus.currentLat, bus.currentLng), 15.0); 
    } else if (bus == null) {
      _lastTrackedBusId = null;
    }
  }

  @override
  void dispose() {
    _transitProvider?.removeListener(_onProviderUpdated);
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchRealLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() { _isGettingLocation = false; _hasValidLocation = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() { _isGettingLocation = false; _hasValidLocation = false; });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() { _isGettingLocation = false; _hasValidLocation = false; });
      return;
    }

    // Permission is granted! Enable the marker.
    if (mounted) {
      setState(() {
        _hasValidLocation = true;
      });
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _centerLatLng = _userLocation;
          _isGettingLocation = false;
        });
        _mapController.move(_userLocation, 14.0);
      }
    } catch (_) {
      if (mounted) setState(() { _isGettingLocation = false; });
    }
  }

  // Helper method to extract coordinates strictly between Origin and Destination
  List<LatLng> _getSubPathCoordinates(TransitProvider provider) {
    final bus = provider.selectedBus;
    if (bus == null || _targetOrigin == null || _targetDestination == null) return [];

    List<LatLng> subPath = [];
    bool isRecording = false;

    for (String stopId in bus.stopIds) {
      final stopMatch = provider.stops.where((s) => s.id == stopId);
      if (stopMatch.isNotEmpty) {
        final stop = stopMatch.first;
        final stopNameEn = stop.nameEn.toLowerCase();
        final stopNameBn = stop.nameBn;
        final orig = _targetOrigin!.toLowerCase();
        final dest = _targetDestination!.toLowerCase();

        if (stopNameEn.contains(orig) || orig.contains(stopNameEn) || stopNameBn.contains(_targetOrigin!)) {
          isRecording = true;
        }

        if (isRecording) {
          subPath.add(LatLng(stop.lat, stop.lng));
        }

        if (stopNameEn.contains(dest) || dest.contains(stopNameEn) || stopNameBn.contains(_targetDestination!)) {
          isRecording = false;
          break;
        }
      }
    }
    return subPath.isNotEmpty ? subPath : provider.getSelectedRouteCoordinates();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context); 
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final baseTileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.dhaka_bus_tracker',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.t('Dhaka Bus Tracker'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showSmartPlan = !_showSmartPlan;
              });
            },
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white, size: 20),
                SizedBox(width: 4),
                Icon(Icons.route, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
      body: provider.isLoading || _isGettingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
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
                        // 1. Full bus route context polyline (Lighter/Dotted)
                        if (provider.selectedBus != null)
                          Polyline<Object>(
                            points: provider.getSelectedRouteCoordinates(),
                            color: Colors.blueAccent.withOpacity(0.35),
                            strokeWidth: 4.0,
                            pattern: const StrokePattern.dotted(),
                          ),
                        
                        // 2. Deep highlighted sub-path strictly between Origin and Destination
                        if (provider.selectedBus != null && _targetOrigin != null && _targetDestination != null)
                          Polyline<Object>(
                            points: _getSubPathCoordinates(provider),
                            color: Colors.deepOrange,
                            strokeWidth: 6.5,
                          ),
                      ],
                    ),

                    MarkerLayer(
                      markers: [
                        // Show marker if settings allow AND permission/location was successfully allowed
                        if (settingsProvider.locationAccess && _hasValidLocation)
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
                                  showArrivalsBottomSheet(
                                    context: context, 
                                    stop: stop, 
                                    provider: provider, 
                                    langProvider: langProvider
                                  );
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
                
                if (_showSmartPlan)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: SmartPlanPanel(
                      onClose: () => setState(() => _showSmartPlan = false),
                      onBusSelected: () => setState(() => _showSmartPlan = false),
                    ),
                  ),

                if (provider.selectedBus != null && !_showSmartPlan)
                  const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: SelectedBusCard(), 
                  ),
              ],
            ),
    );
  }
}