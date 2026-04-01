class ToiletDetail {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String openStatus;
  final bool isDisabled;
  final bool isGenderSep;
  final String? openHours;
  final String source;
  final Map<String, int> crowdSummary;
  final String? currentCrowd;
  final double? averageRating;  // 백엔드 신규 필드
  final int reviewCount;        // 백엔드 신규 필드

  const ToiletDetail({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.openStatus,
    required this.isDisabled,
    required this.isGenderSep,
    this.openHours,
    required this.source,
    required this.crowdSummary,
    this.currentCrowd,
    this.averageRating,
    this.reviewCount = 0,
  });

  factory ToiletDetail.fromJson(Map<String, dynamic> json) => ToiletDetail(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    address: json['address'] as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    openStatus: json['openStatus'] as String,
    isDisabled: json['disabled'] as bool,
    isGenderSep: json['genderSep'] as bool,
    openHours: json['openHours'] as String?,
    source: json['source'] as String,
    crowdSummary: (json['crowdSummary'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
    ),
    currentCrowd: json['currentCrowd'] as String?,
    averageRating: json['averageRating'] == null
        ? null
        : (json['averageRating'] as num).toDouble(),
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
  );

  int get crowdedCount => crowdSummary['CROWDED'] ?? 0;
  int get normalCount  => crowdSummary['NORMAL']  ?? 0;
  int get emptyCount   => crowdSummary['EMPTY']   ?? 0;

  String get ratingDisplay => averageRating != null
      ? averageRating!.toStringAsFixed(1)
      : '-';
}
