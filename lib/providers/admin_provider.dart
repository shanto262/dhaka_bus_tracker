import 'dart:async';
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
    // Listen to Auth State Changes
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _fetchAdminProfile(user.uid);
      } else {
        _companyName = null;
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

    // Rule: Student Fare is exactly half, rounded up if necessary.
    double newStudentFare = (newStandardFare / 2).ceilToDouble(); 

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