class ToiletSummary {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String openStatus;
  final bool isDisabled;
  final bool isGenderSep;

  const ToiletSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.openStatus,
    required this.isDisabled,
    required this.isGenderSep,
  });

  factory ToiletSummary.fromJson(Map<String, dynamic> json) => ToiletSummary(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    address: json['address'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    openStatus: json['openStatus'] as String,
    isDisabled: json['disabled'] as bool,
    isGenderSep: json['genderSep'] as bool,
  );
}
