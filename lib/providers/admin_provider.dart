import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _companyName;
  String? get companyName => _companyName;

  // Data Collections
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> get buses => _buses;

  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> get staff => _staff;

  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> get complaints => _complaints;

  Map<String, dynamic>? _fareMatrix;
  Map<String, dynamic>? get fareMatrix => _fareMatrix;

  // Stream Subscriptions
  StreamSubscription? _busSub;
  StreamSubscription? _staffSub;
  StreamSubscription? _complaintSub;
  StreamSubscription? _fareSub;

  AdminProvider() {
    _initSession();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  void _cancelSubscriptions() {
    _busSub?.cancel();
    _staffSub?.cancel();
    _complaintSub?.cancel();
    _fareSub?.cancel();
  }

  // ============================================================
  // AUTHENTICATION & DATA SCOPING
  // ============================================================
  
  Future<void> _initSession() async {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchAdminProfile(user.uid);
      } else {
        _companyName = null;
        _isLoading = false;
        _cancelSubscriptions();
        notifyListeners();
      }
    });
  }

  Future<void> _fetchAdminProfile(String uid) async {
    try {
      final doc = await _firestore.collection('company_admins').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _companyName = doc.data()!['company'];
        _subscribeToCompanyData();
      } else {
        debugPrint('Admin profile not found in Firestore.');
      }
    } catch (e) {
      debugPrint('Error fetching admin profile: $e');
    }
  }

  void _subscribeToCompanyData() {
    if (_companyName == null) return;

    _cancelSubscriptions(); // Clear old streams if re-authenticating

    // 1. Listen to Company Buses
    _busSub = _firestore
        .collection('buses')
        .where('company', isEqualTo: _companyName)
        .snapshots()
        .listen((snapshot) {
      _buses = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });

    // 2. Listen to Company Staff
    _staffSub = _firestore
        .collection('staff')
        .where('company', isEqualTo: _companyName)
        .snapshots()
        .listen((snapshot) {
      _staff = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });

    // 3. Listen to Company Complaints (Triaging)
    _complaintSub = _firestore
        .collection('complaints')
        .where('company_name', isEqualTo: _companyName)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _complaints = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });

    // 4. Listen to Company Fare Matrices
    _fareSub = _firestore
        .collection('fare_matrices')
        .where('company', isEqualTo: _companyName)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _fareMatrix = {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()};
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // ============================================================
  // FARE MATRIX MANAGEMENT
  // ============================================================

  /// Updates the standard fare between two stops and auto-calculates the student fare.
  Future<void> updateFare(String routeId, String stopPairKey, double newStandardFare) async {
    if (_companyName == null) return;

    // Calculate half fare, but enforce the 10 BDT absolute minimum
    double newStudentFare = (newStandardFare / 2).ceilToDouble(); 
    if (newStudentFare < 10.0) {
      newStudentFare = 10.0;
    }

    try {
      await _firestore.collection('fare_matrices').doc(routeId).set({
        'matrix': {
          stopPairKey: {
            'standard': newStandardFare,
            'student': newStudentFare,
          }
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating fare: $e');
    }
  }

  /// Auto-generates a complete fare matrix using geospatial distance.
  Future<void> autoGenerateFareMatrix(String docId, List<String> stopNames) async {
    try {
      final stopsSnapshot = await _firestore.collection('bus_stops').get();
      final Map<String, Map<String, double>> stopCoords = {};

      for (var doc in stopsSnapshot.docs) {
        final data = doc.data();
        if (data['nameEn'] != null && data['lat'] != null && data['lng'] != null) {
          stopCoords[data['nameEn']] = {'lat': data['lat'], 'lng': data['lng']};
        }
      }

      double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        var p = 0.017453292519943295; 
        var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
            cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
        return 12742 * asin(sqrt(a)); 
      }

      Map<String, dynamic> newMatrix = {};
      const double ratePerKm = 2.50; 
      const double minFare = 10.0;

      for (int i = 0; i < stopNames.length; i++) {
        for (int j = i + 1; j < stopNames.length; j++) {
          String origin = stopNames[i];
          String destination = stopNames[j];
          
          final c1 = stopCoords[origin];
          final c2 = stopCoords[destination];

          if (c1 != null && c2 != null) {
            double distanceKm = calculateDistance(c1['lat']!, c1['lng']!, c2['lat']!, c2['lng']!);
            double rawFare = distanceKm * ratePerKm;
            
            // Round standard fare to nearest 5 BDT and enforce 10 BDT min
            double standardFare = (rawFare / 5).round() * 5.0;
            if (standardFare < minFare) standardFare = minFare;
            
            // Calculate student fare and enforce the same 10 BDT min
            double studentFare = (standardFare / 2).ceilToDouble();
            if (studentFare < 10.0) {
              studentFare = 10.0;
            }

            newMatrix['${origin}_${destination}'] = {
              'standard': standardFare,
              'student': studentFare,
            };
          }
        }
      }

      await _firestore.collection('fare_matrices').doc(docId).set({
        'matrix': newMatrix
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Error generating matrix: $e');
    }
  }

// ============================================================
  // SHIFT RESOLUTION & ATTRIBUTION LOGIC
  // ============================================================

  String _determineActiveShift(DateTime complaintTime, Map<String, dynamic> shifts) {
    final double complaintHour = complaintTime.hour + (complaintTime.minute / 60.0);

    for (var entry in shifts.entries) {
      final shiftName = entry.key; 
      final timeWindow = entry.value['timeWindow'] as String; 

      final parts = timeWindow.split(' - ');
      if (parts.length == 2) {
        final startParts = parts[0].split(':');
        final endParts = parts[1].split(':');

        final startHour = int.parse(startParts[0]) + (int.parse(startParts[1]) / 60.0);
        final endHour = int.parse(endParts[0]) + (int.parse(endParts[1]) / 60.0);

        if (complaintHour >= startHour && complaintHour < endHour) {
          return shiftName; 
        }
      }
    }
    return 'Unknown';
  }

  /// Evaluates a complaint and returns the exact staff on duty.
  Map<String, dynamic>? getAttributionForComplaint(Map<String, dynamic> complaint) {
    final busId = complaint['bus_id'];
    if (busId == null) return null;

    // 1. Find the matching bus (case-insensitive)
    final bus = _buses.firstWhere(
      (b) => b['routeTag']?.toString().toLowerCase() == busId.toString().toLowerCase(), 
      orElse: () => {}
    );
    
    if (bus.isEmpty || !bus.containsKey('shifts')) return null;

    // 2. Safely parse the complaint timestamp
    DateTime complaintTime;
    if (complaint['timestamp'] is Timestamp) {
      complaintTime = (complaint['timestamp'] as Timestamp).toDate();
    } else {
      complaintTime = DateTime.now(); // Fallback if still pending write
    }

    // 3. Determine the shift
    String activeShift = _determineActiveShift(complaintTime, bus['shifts']);
    if (activeShift == 'Unknown') return null;

    // 4. Extract Staff IDs
    String driverId = bus['shifts'][activeShift]['driverId'] ?? '';
    String conductorId = bus['shifts'][activeShift]['conductorId'] ?? '';

    // 5. Look up their real names in the staff list
    final driver = _staff.firstWhere((s) => s['id'] == driverId, orElse: () => {'name': 'Unknown'});
    final conductor = _staff.firstWhere((s) => s['id'] == conductorId, orElse: () => {'name': 'Unknown'});

    return {
      'shift': activeShift,
      'driverId': driverId,
      'driverName': driver['name'],
      'conductorId': conductorId,
      'conductorName': conductor['name'],
    };
  }

  // ============================================================
  // COMPLAINT TRIAGING & STAFF ATTRIBUTION
  // ============================================================

  /// Pins a complaint to a specific staff member and adds a strike to their profile.
  Future<void> resolveAndPinComplaint(String complaintId, String staffId, String resolutionNote) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Update the complaint status
      final complaintRef = _firestore.collection('complaints').doc(complaintId);
      batch.update(complaintRef, {
        'status': 'resolved',
        'pinnedStaffId': staffId,
        'resolutionNote': resolutionNote,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // 2. Append the strike to the staff member's history
      final staffRef = _firestore.collection('staff').doc(staffId);
      batch.update(staffRef, {
        'complaintsCount': FieldValue.increment(1),
        'complaintHistory': FieldValue.arrayUnion([{
          'complaintId': complaintId,
          'note': resolutionNote,
          'timestamp': DateTime.now().toIso8601String(),
        }])
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error resolving complaint: $e');
    }
  }

  /// Dismisses a complaint if it is found to be false or unverifyable.
  Future<void> dismissComplaint(String complaintId, String reason) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': 'dismissed',
        'dismissalReason': reason,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error dismissing complaint: $e');
    }
  }
}