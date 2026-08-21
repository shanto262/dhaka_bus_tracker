import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';

class TransitProvider extends ChangeNotifier {
  List<BusStop> _stops = [];
  List<Bus> _allBuses = [];
  
  BusStop? _selectedStop;
  Bus? _selectedBus;
  bool _isLoading = true;

  List<BusStop> get stops => _stops;
  BusStop? get selectedStop => _selectedStop;
  Bus? get selectedBus => _selectedBus;
  bool get isLoading => _isLoading;

  TransitProvider() {
    loadTransitData();
  }

  Future<void> loadTransitData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/dhaka_routes.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      _stops = (data['stops'] as List).map((i) => BusStop.fromJson(i)).toList();
      _allBuses = (data['buses'] as List).map((i) => Bus.fromJson(i)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading transit data: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectStop(BusStop stop) {
    _selectedStop = stop;
    _selectedBus = null; // Clear tracked bus when a new stop is clicked
    notifyListeners();
  }

  void clearStopSelection() {
    _selectedStop = null;
    _selectedBus = null;
    notifyListeners();
  }

  void selectBus(Bus bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  List<Bus> getBusesForSelectedStop() {
    if (_selectedStop == null) return [];
    return _allBuses.where((b) => b.nextStopId == _selectedStop!.id).toList();
  }
}