class Bus {
  final String busId;
  final String company;
  final String companyBn;
  final String routeTag;
  final String routeName;
  final String licensePlate;
  final double standardFare;
  final double studentFare;
  final String nextStopId;
  final int etaMinutes;
  final bool isLive;
  double currentLat;
  double currentLng;

  Bus({
    required this.busId,
    required this.company,
    required this.companyBn,
    required this.routeTag,
    required this.routeName,
    required this.licensePlate,
    required this.standardFare,
    required this.studentFare,
    required this.nextStopId,
    required this.etaMinutes,
    required this.isLive,
    required this.currentLat,
    required this.currentLng,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      busId: json['busId'],
      company: json['company'],
      companyBn: json['companyBn'],
      routeTag: json['routeTag'],
      routeName: json['routeName'],
      licensePlate: json['licensePlate'],
      standardFare: (json['standardFare'] as num).toDouble(),
      studentFare: (json['studentFare'] as num).toDouble(),
      nextStopId: json['nextStopId'],
      etaMinutes: json['etaMinutes'],
      isLive: json['isLive'],
      currentLat: (json['currentLat'] as num).toDouble(),
      currentLng: (json['currentLng'] as num).toDouble(),
    );
  }
}