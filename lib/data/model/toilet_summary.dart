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

// ── 키워드 검색 결과 ────────────────────────────────────────────────────────
class ToiletSearchResult {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String openStatus;
  final bool isDisabled;
  final bool isGenderSep;
  final double? distanceMeters;

  const ToiletSearchResult({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.openStatus,
    required this.isDisabled,
    required this.isGenderSep,
    this.distanceMeters,
  });

  factory ToiletSearchResult.fromJson(Map<String, dynamic> json) =>
      ToiletSearchResult(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        address: json['address'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        openStatus: json['openStatus'] as String,
        isDisabled: json['disabled'] as bool,
        isGenderSep: json['genderSep'] as bool,
        distanceMeters: json['distanceMeters'] == null
            ? null
            : (json['distanceMeters'] as num).toDouble(),
      );

  /// 1000m 미만 → "123m", 이상 → "1.2km"
  String? get distanceLabel {
    if (distanceMeters == null) return null;
    return distanceMeters! < 1000
        ? '${distanceMeters!.toInt()}m'
        : '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }
}
