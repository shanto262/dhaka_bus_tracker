import 'package:flutter/material.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';

class TransitProvider extends ChangeNotifier {
  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  BusStop? _selectedStop;
  BusStop? get selectedStop => _selectedStop;

  Bus? _selectedBus;
  Bus? get selectedBus => _selectedBus;

  // Real Major Dhaka Bus Stops
  final List<BusStop> _stops = [
    BusStop(id: 'stop_1', nameEn: 'Farmgate', nameBn: 'ফার্মগেট', lat: 23.7561, lng: 90.3872),
    BusStop(id: 'stop_2', nameEn: 'Shahbagh', nameBn: 'শাহবাগ', lat: 23.7380, lng: 90.3956),
    BusStop(id: 'stop_3', nameEn: 'Mirpur 10', nameBn: 'মিরপুর ১০', lat: 23.8069, lng: 90.3687),
    BusStop(id: 'stop_4', nameEn: 'Uttara (House Building)', nameBn: 'উত্তরা (হাউস বিল্ডিং)', lat: 23.8738, lng: 90.3965),
    BusStop(id: 'stop_5', nameEn: 'Motijheel', nameBn: 'মতিঝিল', lat: 23.7330, lng: 90.4175),
    BusStop(id: 'stop_6', nameEn: 'Mohakhali', nameBn: 'মহাখালী', lat: 23.7776, lng: 90.4005),
    BusStop(id: 'stop_7', nameEn: 'Dhanmondi 32', nameBn: 'ধানমন্ডি ৩২', lat: 23.7510, lng: 90.3770),
    BusStop(id: 'stop_8', nameEn: 'Airport', nameBn: 'বিমানবন্দর', lat: 23.8510, lng: 90.4076),
  ];

  // Active Buses Running Across Routes with complete metadata
  final List<Bus> _buses = [
    Bus(
      busId: 'bus_101',
      company: 'Bikash Paribahan',
      companyBn: 'বিকাশ পরিবহন',
      routeTag: 'A-101',
      routeName: 'Mirpur 10 ➔ Motijheel',
      licensePlate: 'Dhaka Metro-Ba 11-4521',
      standardFare: 35.0,
      studentFare: 18.0,
      nextStopId: 'stop_1',
      etaMinutes: 4,
      isLive: true,
      currentLat: 23.7580,
      currentLng: 90.3890,
      stopIds: ['stop_3', 'stop_1', 'stop_2', 'stop_5'],
    ),
    Bus(
      busId: 'bus_102',
      company: 'Uttara Express',
      companyBn: 'উত্তরা এক্সপ্রেস',
      routeTag: 'U-205',
      routeName: 'Uttara ➔ Shahbagh',
      licensePlate: 'Dhaka Metro-Cha 14-8890',
      standardFare: 40.0,
      studentFare: 20.0,
      nextStopId: 'stop_8',
      etaMinutes: 8,
      isLive: true,
      currentLat: 23.8650,
      currentLng: 90.3980,
      stopIds: ['stop_4', 'stop_8', 'stop_6', 'stop_1', 'stop_2'],
    ),
    Bus(
      busId: 'bus_103',
      company: 'BRTC Articulated',
      companyBn: 'বিআরটিসি আর্টিকুলেটেড',
      routeTag: 'B-77',
      routeName: 'Airport ➔ Motijheel',
      licensePlate: 'Dhaka Metro-Ba 15-1122',
      standardFare: 30.0,
      studentFare: 15.0,
      nextStopId: 'stop_6',
      etaMinutes: 12,
      isLive: false,
      currentLat: 23.7410,
      currentLng: 90.3970,
      stopIds: ['stop_4', 'stop_8', 'stop_6', 'stop_2', 'stop_5'],
    ),
    Bus(
      busId: 'bus_104',
      company: 'Thikana Paribahan',
      companyBn: 'ঠিকানা পরিবহন',
      routeTag: 'T-12',
      routeName: 'Mirpur 10 ➔ Motijheel (via Dhanmondi)',
      licensePlate: 'Dhaka Metro-Cha 12-3344',
      standardFare: 35.0,
      studentFare: 18.0,
      nextStopId: 'stop_7',
      etaMinutes: 6,
      isLive: true,
      currentLat: 23.7530,
      currentLng: 90.3790,
      stopIds: ['stop_3', 'stop_7', 'stop_2', 'stop_5'],
    ),
  ];

  List<BusStop> get stops => _stops;
  List<Bus> get buses => _buses;

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
    return _buses.where((bus) => bus.stopIds.contains(_selectedStop!.id)).toList();
  }
}