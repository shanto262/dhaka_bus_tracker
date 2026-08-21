class BusStop {
  final String id;
  final String nameEn;
  final String nameBn;
  final double lat;
  final double lng;

  BusStop({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.lat,
    required this.lng,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'],
      nameEn: json['nameEn'],
      nameBn: json['nameBn'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}