import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final List<Map<String, dynamic>> _allStops = [
    {'nameEn': 'Abdullahpur', 'nameBn': 'আব্দুল্লাহপুর', 'lat': 23.8825, 'lng': 90.3980},
    {'nameEn': 'Uttara House Building', 'nameBn': 'উত্তরা হাউস বিল্ডিং', 'lat': 23.8738, 'lng': 90.3965},
    {'nameEn': 'Azampur', 'nameBn': 'আজমপুর', 'lat': 23.8680, 'lng': 90.4000},
    {'nameEn': 'Airport', 'nameBn': 'বিমানবন্দর', 'lat': 23.8510, 'lng': 90.4076},
    {'nameEn': 'Khilkhet', 'nameBn': 'খিলক্ষেত', 'lat': 23.8290, 'lng': 90.4180},
    {'nameEn': 'Kuril Bishwa Road', 'nameBn': 'কুড়িল বিশ্বরোড', 'lat': 23.8160, 'lng': 90.4200},
    {'nameEn': 'Banani', 'nameBn': 'বনানী', 'lat': 23.7937, 'lng': 90.4043},
    {'nameEn': 'Mohakhali', 'nameBn': 'মহাখালী', 'lat': 23.7776, 'lng': 90.4005},
    {'nameEn': 'Jahangir Gate', 'nameBn': 'জাহাঙ্গীর গেট', 'lat': 23.7690, 'lng': 90.3920},
    {'nameEn': 'Bijoy Sarani', 'nameBn': 'বিজয় সরণি', 'lat': 23.7630, 'lng': 90.3890},
    {'nameEn': 'Farmgate', 'nameBn': 'ফার্মগেট', 'lat': 23.7561, 'lng': 90.3872},
    {'nameEn': 'Kawran Bazar', 'nameBn': 'কাওরান বাজার', 'lat': 23.7505, 'lng': 90.3935},
    {'nameEn': 'Banglamotor', 'nameBn': 'বাংলামোটর', 'lat': 23.7460, 'lng': 90.3945},
    {'nameEn': 'Shahbagh', 'nameBn': 'শাহবাগ', 'lat': 23.7380, 'lng': 90.3956},
    {'nameEn': 'Press Club', 'nameBn': 'প্রেস ক্লাব', 'lat': 23.7300, 'lng': 90.4080},
    {'nameEn': 'Paltan', 'nameBn': 'পল্টন', 'lat': 23.7310, 'lng': 90.4140},
    {'nameEn': 'Gulistan', 'nameBn': 'গুলিস্তান', 'lat': 23.7250, 'lng': 90.4121},
    {'nameEn': 'Motijheel', 'nameBn': 'মতিঝিল', 'lat': 23.7330, 'lng': 90.4175},
    {'nameEn': 'Sayedabad', 'nameBn': 'সায়েদাবাদ', 'lat': 23.7140, 'lng': 90.4280},
    {'nameEn': 'Jatrabari', 'nameBn': 'যাত্রাবাড়ী', 'lat': 23.7100, 'lng': 90.4340},
    {'nameEn': 'Mirpur 12', 'nameBn': 'মিরপুর ১২', 'lat': 23.8270, 'lng': 90.3640},
    {'nameEn': 'Mirpur 11', 'nameBn': 'মিরপুর ১১', 'lat': 23.8170, 'lng': 90.3660},
    {'nameEn': 'Mirpur 10', 'nameBn': 'মিরপুর ১০', 'lat': 23.8069, 'lng': 90.3687},
    {'nameEn': 'Mirpur 2', 'nameBn': 'মিরপুর ২', 'lat': 23.8010, 'lng': 90.3550},
    {'nameEn': 'Mirpur 1', 'nameBn': 'মিরপুর ১', 'lat': 23.7950, 'lng': 90.3530},
    {'nameEn': 'Technical', 'nameBn': 'টেকনিক্যাল', 'lat': 23.7850, 'lng': 90.3510},
    {'nameEn': 'Gabtoli', 'nameBn': 'গাবতলী', 'lat': 23.7844, 'lng': 90.3443},
    {'nameEn': 'Kalyanpur', 'nameBn': 'কল্যাণপুর', 'lat': 23.7780, 'lng': 90.3610},
    {'nameEn': 'Shyamoli', 'nameBn': 'শ্যামলী', 'lat': 23.7710, 'lng': 90.3650},
    {'nameEn': 'Asad Gate', 'nameBn': 'আসাদ গেট', 'lat': 23.7600, 'lng': 90.3720},
    {'nameEn': 'Dhanmondi 27', 'nameBn': 'ধানমন্ডি ২৭', 'lat': 23.7550, 'lng': 90.3730},
    {'nameEn': 'Dhanmondi 32', 'nameBn': 'ধানমন্ডি ৩২', 'lat': 23.7510, 'lng': 90.3770},
    {'nameEn': 'Kalabagan', 'nameBn': 'কলাবাগান', 'lat': 23.7480, 'lng': 90.3800},
    {'nameEn': 'Science Lab', 'nameBn': 'সায়েন্স ল্যাব', 'lat': 23.7400, 'lng': 90.3840},
    {'nameEn': 'New Market', 'nameBn': 'নিউ মার্কেট', 'lat': 23.7330, 'lng': 90.3850},
    {'nameEn': 'Nilkhet', 'nameBn': 'নীলক্ষেত', 'lat': 23.7320, 'lng': 90.3880},
    {'nameEn': 'Azimpur', 'nameBn': 'আজিমপুর', 'lat': 23.7270, 'lng': 90.3850},
    {'nameEn': 'Gulshan 1', 'nameBn': 'গুলশান ১', 'lat': 23.7790, 'lng': 90.4170},
    {'nameEn': 'Gulshan 2', 'nameBn': 'গুলশান ২', 'lat': 23.7940, 'lng': 90.4140},
    {'nameEn': 'Badda', 'nameBn': 'বাড্ডা', 'lat': 23.7830, 'lng': 90.4260},
    {'nameEn': 'Rampura', 'nameBn': 'রামপুরা', 'lat': 23.7630, 'lng': 90.4230},
    {'nameEn': 'Malibagh', 'nameBn': 'মালিবাগ', 'lat': 23.7480, 'lng': 90.4150},
    {'nameEn': 'Moghbazar', 'nameBn': 'মগবাজার', 'lat': 23.7500, 'lng': 90.4050},
    {'nameEn': 'Kakrail', 'nameBn': 'কাকরাইল', 'lat': 23.7400, 'lng': 90.4070},
    {'nameEn': 'Signboard', 'nameBn': 'সাইনবোর্ড', 'lat': 23.6890, 'lng': 90.4850},
  ];

  static Future<void> seedLargeTransitData({bool forceReset = false}) async {
    final existingStops = await _db.collection('bus_stops').get();
    
    if (existingStops.docs.length >= 20 && !forceReset) {
      debugPrint('ℹ️ Database already scaled with ${existingStops.docs.length} stops.');
      return;
    }

    debugPrint('🚀 Starting full Dhaka transit data scale-up...');

    if (forceReset) {
      // Clear out all relevant collections so you have a clean slate for testing
      final collectionsToClear = ['bus_stops', 'buses', 'staff', 'fare_matrices', 'complaints'];
      for (String col in collectionsToClear) {
        final snapshot = await _db.collection(col).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
    }

    WriteBatch batch = _db.batch();
    Map<String, String> nameToIdMap = {};

    for (var stop in _allStops) {
      DocumentReference docRef = _db.collection('bus_stops').doc();
      batch.set(docRef, stop);
      nameToIdMap[stop['nameEn'] as String] = docRef.id;
    }
    await batch.commit();
    debugPrint('✅ ${_allStops.length} bus stops written via Batch.');

    List<String> getIds(List<String> names) {
      return names
          .map((name) => nameToIdMap[name])
          .where((id) => id != null)
          .cast<String>()
          .toList();
    }

    // ==========================================
    // BIKASH PARIBAHAN SETUP 
    // ==========================================
    const bikashCompany = 'Bikash Paribahan';
    List<String> driverIds = [];
    List<String> conductorIds = [];
    
    final List<String> driverNames = [
      'Md. Shafiqul Islam', 'Kamrul Hasan', 'Abdur Rahman', 'Tariqul Islam', 'Jamal Uddin',
      'Faruk Hossain', 'Nazmul Huda', 'Habibur Rahman', 'Mizanur Rahman', 'Ashraful Islam'
    ];

    final List<String> conductorNames = [
      'Arifur Rahman', 'Raju Ahmed', 'Liton Das', 'Sohail Rana', 'Sumon Ali',
      'Ripon Mia', 'Jahid Hasan', 'Mehedi Hasan', 'Rakibul Islam', 'Sabbir Hossain'
    ];
    
    // 1. Create 20 Staff Members (10 Drivers, 10 Conductors)
    for (int i = 1; i <= 10; i++) {
      final driverRef = await _db.collection('staff').add({
        'name': driverNames[i - 1],
        'role': 'driver',
        'phone': '017000000${i.toString().padLeft(2, '0')}', 
        'company': bikashCompany,
        'complaintsCount': 0,
        'complaintHistory': [],
      });
      driverIds.add(driverRef.id);

      final conductorRef = await _db.collection('staff').add({
        'name': conductorNames[i - 1],
        'role': 'conductor',
        'phone': '019000000${i.toString().padLeft(2, '0')}',
        'company': bikashCompany,
        'complaintsCount': 0,
        'complaintHistory': [],
      });
      conductorIds.add(conductorRef.id);
    }

    final bikashStops = ['Mirpur 12', 'Mirpur 11', 'Mirpur 10', 'Mirpur 2', 'Mirpur 1', 'Technical', 'Kalyanpur', 'Shyamoli', 'Asad Gate', 'Science Lab', 'New Market', 'Nilkhet', 'Azimpur'];
    final bikashStopIds = getIds(bikashStops);

    // 2. Create Fare Matrix
    await _db.collection('fare_matrices').add({
      'company': bikashCompany,
      'stops': bikashStops,
      'matrix': {
        'Mirpur 12_Mirpur 11': {'standard': 10.0, 'student': 5.0},
      }
    });

    // 3. Build Route Data
    List<Map<String, dynamic>> routes = [];

    for (int i = 1; i <= 5; i++) {
      routes.add({
        'company': bikashCompany,
        'companyBn': 'বিকাশ পরিবহন',
        'routeTag': 'bk-10$i',
        'routeName': 'Mirpur 12 ➔ Azimpur',
        'licensePlate': 'Dhaka Metro-Ba 11-450$i', 
        'standardFare': 35.0,
        'studentFare': 18.0,
        'nextStopId': nameToIdMap['Mirpur 10'] ?? '',
        'etaMinutes': 2 + i, 
        'isLive': true,
        'currentLat': 23.8120 - (i * 0.003), 
        'currentLng': 90.3670,
        'stopIds': bikashStopIds,
        'shifts': {
          'morning': {
            'timeWindow': '06:00 - 14:00',
            // Uses staff 1 to 5
            'driverId': driverIds[i - 1],
            'conductorId': conductorIds[i - 1],
          },
          'evening': {
            'timeWindow': '14:00 - 22:00',
            // Uses staff 6 to 10
            'driverId': driverIds[i + 4], 
            'conductorId': conductorIds[i + 4],
          }
        }
      });
    }

    // Add the remaining static companies
    routes.addAll([
      {
        'company': 'Prajapati Paribahan',
        'companyBn': 'প্রজাপতি পরিবহন',
        'routeTag': 'PJ-204',
        'routeName': 'Mirpur 14 ➔ Abdullahpur',
        'licensePlate': 'Dhaka Metro-Ba 14-3310',
        'standardFare': 40.0,
        'studentFare': 20.0,
        'nextStopId': nameToIdMap['Airport'] ?? '',
        'etaMinutes': 6,
        'isLive': true,
        'currentLat': 23.8450,
        'currentLng': 90.4090,
        'stopIds': getIds(['Mirpur 10', 'Mirpur 11', 'Mirpur 12', 'Kuril Bishwa Road', 'Khilkhet', 'Airport', 'Azampur', 'Uttara House Building', 'Abdullahpur']),
      },
      {
        'company': 'Raida Enterprise',
        'companyBn': 'রাইদা এন্টারপ্রাইজ',
        'routeTag': 'RD-302',
        'routeName': 'Postogola ➔ Abdullahpur',
        'licensePlate': 'Dhaka Metro-Ba 15-8821',
        'standardFare': 55.0,
        'studentFare': 25.0,
        'nextStopId': nameToIdMap['Kuril Bishwa Road'] ?? '',
        'etaMinutes': 5,
        'isLive': true,
        'currentLat': 23.8100,
        'currentLng': 90.4210,
        'stopIds': getIds(['Jatrabari', 'Sayedabad', 'Malibagh', 'Rampura', 'Badda', 'Kuril Bishwa Road', 'Khilkhet', 'Airport', 'Azampur', 'Uttara House Building', 'Abdullahpur']),
      },
      {
        'company': 'Turag Paribahan',
        'companyBn': 'তুরাগ পরিবহন',
        'routeTag': 'TR-501',
        'routeName': 'Jatrabari ➔ Tongi',
        'licensePlate': 'Dhaka Metro-Cha 12-9901',
        'standardFare': 50.0,
        'studentFare': 25.0,
        'nextStopId': nameToIdMap['Badda'] ?? '',
        'etaMinutes': 9,
        'isLive': true,
        'currentLat': 23.7750,
        'currentLng': 90.4270,
        'stopIds': getIds(['Jatrabari', 'Sayedabad', 'Malibagh', 'Rampura', 'Badda', 'Kuril Bishwa Road', 'Khilkhet', 'Airport', 'Abdullahpur']),
      },
      {
        'company': 'BRTC Articulated',
        'companyBn': 'বিআরটিসি আর্টিকুলেটেড',
        'routeTag': 'BR-01',
        'routeName': 'Motijheel ➔ Abdullahpur (VIP Route)',
        'licensePlate': 'Dhaka Metro-Ba 18-0012',
        'standardFare': 60.0,
        'studentFare': 30.0,
        'nextStopId': nameToIdMap['Farmgate'] ?? '',
        'etaMinutes': 4,
        'isLive': true,
        'currentLat': 23.7530,
        'currentLng': 90.3900,
        'stopIds': getIds(['Motijheel', 'Paltan', 'Press Club', 'Shahbagh', 'Banglamotor', 'Kawran Bazar', 'Farmgate', 'Bijoy Sarani', 'Jahangir Gate', 'Mohakhali', 'Banani', 'Airport', 'Uttara House Building', 'Abdullahpur']),
      },
      {
        'company': 'Thikana Paribahan',
        'companyBn': 'ঠিকানা পরিবহন',
        'routeTag': 'TK-09',
        'routeName': 'Sayedabad ➔ Gabtoli',
        'licensePlate': 'Dhaka Metro-Ba 16-7734',
        'standardFare': 45.0,
        'studentFare': 20.0,
        'nextStopId': nameToIdMap['Dhanmondi 32'] ?? '',
        'etaMinutes': 7,
        'isLive': true,
        'currentLat': 23.7490,
        'currentLng': 90.3780,
        'stopIds': getIds(['Sayedabad', 'Gulistan', 'Shahbagh', 'Science Lab', 'Kalabagan', 'Dhanmondi 32', 'Dhanmondi 27', 'Asad Gate', 'Shyamoli', 'Kalyanpur', 'Technical', 'Gabtoli']),
      },
      {
        'company': 'Prochesta Paribahan',
        'companyBn': 'প্রচেষ্টা পরিবহন',
        'routeTag': 'PR-15',
        'routeName': 'Azimpur ➔ Kuril',
        'licensePlate': 'Dhaka Metro-Cha 11-4099',
        'standardFare': 35.0,
        'studentFare': 18.0,
        'nextStopId': nameToIdMap['Shahbagh'] ?? '',
        'etaMinutes': 2,
        'isLive': true,
        'currentLat': 23.7350,
        'currentLng': 90.3920,
        'stopIds': getIds(['Azimpur', 'Nilkhet', 'Science Lab', 'Shahbagh', 'Moghbazar', 'Malibagh', 'Rampura', 'Badda', 'Kuril Bishwa Road']),
      },
    ]);

    WriteBatch busBatch = _db.batch();
    for (var bus in routes) {
      DocumentReference busRef = _db.collection('buses').doc();
      busBatch.set(busRef, bus);
    }
    await busBatch.commit();
    debugPrint('✅ ${routes.length} bus routes linked and written via Batch!');
  }
}