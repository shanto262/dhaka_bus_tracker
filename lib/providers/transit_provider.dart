import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';

class TransitProvider extends ChangeNotifier {
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

  TransitProvider() {
    fetchTransitData(); // Fetch everything on startup
  }

  Future<void> fetchTransitData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch Stops
      final stopsSnap = await firestore.collection('bus_stops').get();
      _stops = stopsSnap.docs.map((doc) {
        final data = doc.data();
        return BusStop(
          id: doc.id,
          nameEn: data['nameEn'] ?? 'Unknown',
          nameBn: data['nameBn'] ?? 'অজানা',
          lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
          lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      // 2. Fetch Buses
      final busesSnap = await firestore.collection('buses').get();
      _buses = busesSnap.docs.map((doc) {
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

      debugPrint('✅ Loaded ${_stops.length} stops and ${_buses.length} buses from Firestore!');
    } catch (e) {
      debugPrint('❌ Error loading transit data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectStop(BusStop stop) {
    _selectedStop = stop;
    notifyListeners();
  }

  void clearStopSelection() {
    _selectedStop = null;
    notifyListeners();
  }

  void selectBus(Bus bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  List<Bus> getBusesForSelectedStop() {
    if (_selectedStop == null) return [];
    // This will now perfectly match the real Firestore IDs!
    return _buses.where((bus) => bus.stopIds.contains(_selectedStop!.id)).toList();
  }
}