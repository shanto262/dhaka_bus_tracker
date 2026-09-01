import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';

class TransitProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BusStop? _selectedStop;
  BusStop? get selectedStop => _selectedStop;

  Bus? _selectedBus;
  Bus? get selectedBus => _selectedBus;

  List<BusStop> _stops = [];
  List<BusStop> get stops => _stops;

  List<Bus> _buses = [];
  List<Bus> get buses => _buses;

  // Holds the live fare matrix data for the AI Assistant
  List<Map<String, dynamic>> _fareMatrices = [];
  List<Map<String, dynamic>> get fareMatrices => _fareMatrices;

  final Map<String, List<LatLng>> _busDetailedRoutes = {};

  StreamSubscription<QuerySnapshot>? _stopsSubscription;
  StreamSubscription<QuerySnapshot>? _busesSubscription;
  StreamSubscription<QuerySnapshot>? _fareMatricesSubscription;
  Timer? _simulationTimer;

  final Map<String, int> _busTargetIndex = {};
  final Map<String, double> _busStepFraction = {};

  TransitProvider() {
    initLiveTransitStream();
  }

  @override
  void dispose() {
    _stopsSubscription?.cancel();
    _busesSubscription?.cancel();
    _fareMatricesSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void initLiveTransitStream() {
    _isLoading = true;
    notifyListeners();

    // 1. Listen to Stops
    _stopsSubscription = _firestore.collection('bus_stops').snapshots().listen(
      (snapshot) {
        _stops = snapshot.docs.map((doc) {
          final data = doc.data();
          return BusStop(
            id: doc.id,
            nameEn: data['nameEn'] ?? 'Unknown',
            nameBn: data['nameBn'] ?? 'অজানা',
            lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
            lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        _isLoading = false;
        notifyListeners();
      },
    );

    // 2. Listen to Buses
    _busesSubscription = _firestore.collection('buses').snapshots().listen(
      (snapshot) {
        _buses = snapshot.docs.map((doc) {
          final data = doc.data();
          return Bus(
            busId: doc.id,
            company: data['company'] ?? '',
            companyBn: data['companyBn'] ?? '',
            routeTag: data['routeTag'] ?? '',
            routeName: data['routeName'] ?? '',
            licensePlate: data['licensePlate'] ?? '',
            standardFare: (data['standardFare'] as num?)?.toDouble() ?? 0.0,
            studentFare: (data['studentFare'] as num?)?.toDouble() ?? 0.0,
            nextStopId: data['nextStopId'] ?? '',
            etaMinutes: data['etaMinutes'] ?? 0,
            isLive: data['isLive'] ?? false,
            currentLat: (data['currentLat'] as num?)?.toDouble() ?? 0.0,
            currentLng: (data['currentLng'] as num?)?.toDouble() ?? 0.0,
            stopIds: List<String>.from(data['stopIds'] ?? []),
          );
        }).toList();

        _fetchDetailedRoutesFromOSRM().then((_) {
          _startBusSimulation();
        });
        
        notifyListeners();
      },
    );

    // 3. Listen to Fare Matrices
    _fareMatricesSubscription = _firestore.collection('fare_matrices').snapshots().listen(
      (snapshot) {
        _fareMatrices = snapshot.docs.map((doc) => doc.data()).toList();
        notifyListeners();
      },
    );
  }

  Future<void> _fetchDetailedRoutesFromOSRM() async {
    for (var bus in _buses) {
      if (!bus.isLive || bus.stopIds.length < 2) continue;
      if (_busDetailedRoutes.containsKey(bus.busId)) continue;

      try {
        final routeCoords = bus.stopIds
            .map((id) => _stops.firstWhere((s) => s.id == id, orElse: () => BusStop(id: '', nameEn: '', nameBn: '', lat: 0, lng: 0)))
            .where((s) => s.lat != 0 && s.lng != 0)
            .toList();

        if (routeCoords.length < 2) continue;

        final coordinateString = routeCoords.map((c) => '${c.lng},${c.lat}').join(';');
        
        final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/$coordinateString?geometries=geojson&overview=full');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          
          _busDetailedRoutes[bus.busId] = coordinates
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
        }
      } catch (e) {
        debugPrint('OSRM Routing Error: $e');
      }
    }
    notifyListeners();
  }

  void _startBusSimulation() {
    _simulationTimer?.cancel();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_stops.isEmpty || _buses.isEmpty) return;

      bool hasMoved = false;

      for (int i = 0; i < _buses.length; i++) {
        final bus = _buses[i];
        if (!bus.isLive) continue;

        final detailedCoords = _busDetailedRoutes[bus.busId];
        
        if (detailedCoords == null || detailedCoords.length < 2) continue;

        int targetIdx = _busTargetIndex[bus.busId] ?? 1;
        if (targetIdx >= detailedCoords.length) targetIdx = 1;

        int fromIdx = targetIdx - 1;
        final fromPoint = detailedCoords[fromIdx];
        final toPoint = detailedCoords[targetIdx];

        double fraction = (_busStepFraction[bus.busId] ?? 0.0) + 0.3;

        if (fraction >= 1.0) {
          fraction = 0.0;
          targetIdx = (targetIdx + 1) % detailedCoords.length;
          _busTargetIndex[bus.busId] = targetIdx;
        }
        _busStepFraction[bus.busId] = fraction;

        final newLat = fromPoint.latitude + (toPoint.latitude - fromPoint.latitude) * fraction;
        final newLng = fromPoint.longitude + (toPoint.longitude - fromPoint.longitude) * fraction;

        final updatedBus = Bus(
          busId: bus.busId,
          company: bus.company,
          companyBn: bus.companyBn,
          routeTag: bus.routeTag,
          routeName: bus.routeName,
          licensePlate: bus.licensePlate,
          standardFare: bus.standardFare,
          studentFare: bus.studentFare,
          nextStopId: bus.nextStopId, 
          etaMinutes: bus.etaMinutes, 
          isLive: bus.isLive,
          currentLat: newLat,
          currentLng: newLng,
          stopIds: bus.stopIds,
        );

        _buses[i] = updatedBus;

        if (_selectedBus?.busId == updatedBus.busId) {
          _selectedBus = updatedBus;
        }
        hasMoved = true;
      }

      if (hasMoved) {
        notifyListeners();
      }
    });
  }

  void selectStop(BusStop stop) {
    _selectedStop = stop;
    notifyListeners();
  }

  void clearStopSelection() {
    _selectedStop = null;
    _selectedBus = null;
    notifyListeners();
  }

  void selectBus(Bus? bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  List<Bus> getBusesForSelectedStop() {
    if (_selectedStop == null) return [];
    return _buses.where((bus) => bus.stopIds.contains(_selectedStop!.id)).toList();
  }

  List<LatLng> getSelectedRouteCoordinates() {
    if (_selectedBus == null) return [];

    if (_busDetailedRoutes.containsKey(_selectedBus!.busId)) {
      return _busDetailedRoutes[_selectedBus!.busId]!;
    }

    final List<LatLng> points = [];
    for (String stopId in _selectedBus!.stopIds) {
      final match = _stops.where((s) => s.id == stopId);
      if (match.isNotEmpty) {
        points.add(LatLng(match.first.lat, match.first.lng));
      }
    }
    return points;
  }

  int getDynamicEta(Bus bus, BusStop targetStop) {
    if (!bus.isLive) return bus.etaMinutes;

    const distance = Distance();
    
    final meters = distance(
      LatLng(bus.currentLat, bus.currentLng),
      LatLng(targetStop.lat, targetStop.lng),
    );

    int calculatedEta = (meters / 250).ceil();

    return calculatedEta < 1 ? 1 : calculatedEta; 
  }

  // ============================================================
  // SMART TRIP PLANNER LOGIC
  // ============================================================

  List<Bus> getMatchingBuses(BusStop fromStop, BusStop toStop) {
    if (fromStop.id == toStop.id) return [];

    return _buses.where((bus) {
      final fromIndex = bus.stopIds.indexOf(fromStop.id);
      final toIndex = bus.stopIds.lastIndexOf(toStop.id);

      return fromIndex >= 0 && toIndex >= 0 && fromIndex < toIndex;
    }).toList();
  }

  // NEW: Multi-Leg Transfer Finder for Smart Planner
  Map<String, dynamic>? findMultiLegRoute(BusStop from, BusStop to) {
    for (var bus1 in _buses) {
      final fromIndex = bus1.stopIds.indexOf(from.id);
      if (fromIndex == -1) continue;

      for (int i = fromIndex + 1; i < bus1.stopIds.length; i++) {
        final transferStopId = bus1.stopIds[i];

        for (var bus2 in _buses) {
          if (bus1.busId == bus2.busId) continue;

          final transferIndex = bus2.stopIds.indexOf(transferStopId);
          if (transferIndex == -1) continue;

          final toIndex = bus2.stopIds.lastIndexOf(to.id);
          if (toIndex != -1 && toIndex > transferIndex) {
            final transferStop = _stops.firstWhere(
              (s) => s.id == transferStopId,
              orElse: () => _stops.first,
            );

            return {
              'leg1Bus': bus1,
              'leg2Bus': bus2,
              'transferStop': transferStop,
            };
          }
        }
      }
    }
    return null;
  }

  int estimatedTravelTime(Bus bus, BusStop fromStop, BusStop toStop) {
    final fromIndex = bus.stopIds.indexOf(fromStop.id);
    final toIndex = bus.stopIds.lastIndexOf(toStop.id);

    if (fromIndex < 0 || toIndex < 0 || toIndex <= fromIndex) {
      return bus.etaMinutes;
    }

    final numberOfStops = toIndex - fromIndex;
    
    const minutesPerStop = 5;
    final estimated = numberOfStops * minutesPerStop;

    return estimated > 0 ? estimated : bus.etaMinutes;
  }

  Bus? getFastestBus(List<Bus> matchingBuses, BusStop fromStop, BusStop toStop) {
    if (matchingBuses.isEmpty) return null;
    
    final buses = List<Bus>.from(matchingBuses);
    buses.sort((a, b) => estimatedTravelTime(a, fromStop, toStop).compareTo(estimatedTravelTime(b, fromStop, toStop)));
    
    return buses.first;
  }

  Bus? getBestBus(List<Bus> matchingBuses, BusStop fromStop, BusStop toStop) {
    if (matchingBuses.isEmpty) return null;

    Bus best = matchingBuses.first;
    double bestScore = double.infinity;

    for (final bus in matchingBuses) {
      final time = estimatedTravelTime(bus, fromStop, toStop);
      final fare = bus.standardFare;
      
      final score = time + (fare * 0.20) + (bus.isLive ? 0 : 5);

      if (score < bestScore) {
        bestScore = score;
        best = bus;
      }
    }

    return best;
  }
}