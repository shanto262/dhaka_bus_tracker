import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _busArrivalAlerts = true;
  bool _liveMapRefresh = true;
  bool _backgroundDataSync = true;
  bool _locationAccess = true;

  bool get busArrivalAlerts => _busArrivalAlerts;
  bool get liveMapRefresh => _liveMapRefresh;
  bool get backgroundDataSync => _backgroundDataSync;
  bool get locationAccess => _locationAccess;

  void toggleBusArrivalAlerts(bool value) {
    _busArrivalAlerts = value;
    notifyListeners();
  }

  void toggleLiveMapRefresh(bool value) {
    _liveMapRefresh = value;
    notifyListeners();
  }

  void toggleBackgroundDataSync(bool value) {
    _backgroundDataSync = value;
    notifyListeners();
  }

  void toggleLocationAccess(bool value) {
    _locationAccess = value;
    notifyListeners();
  }
}