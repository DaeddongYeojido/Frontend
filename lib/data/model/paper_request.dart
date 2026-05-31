class PaperRequest {
  final int id;
  final int toiletId;
  final String toiletName;
  final double toiletLat;
  final double toiletLng;
  final String deviceId;
  final String gender; // MALE | FEMALE
  final String status; // ACTIVE | RESCUED | EXPIRED
  final DateTime requestedAt;
  final DateTime expiresAt;
  final DateTime? rescuedAt;
  final DateTime? rescueDisplayUntil;
  final int remainingSeconds;

  const PaperRequest({
    required this.id,
    required this.toiletId,
    required this.toiletName,
    required this.toiletLat,
    required this.toiletLng,
    required this.deviceId,
    required this.gender,
    required this.status,
    required this.requestedAt,
    required this.expiresAt,
    this.rescuedAt,
    this.rescueDisplayUntil,
    required this.remainingSeconds,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isRescued => status == 'RESCUED';
  bool get isExpired => status == 'EXPIRED';

  factory PaperRequest.fromJson(Map<String, dynamic> json) => PaperRequest(
    id: (json['id'] as num).toInt(),
    toiletId: (json['toiletId'] as num).toInt(),
    toiletName: json['toiletName'] as String,
    toiletLat: (json['toiletLat'] as num).toDouble(),
    toiletLng: (json['toiletLng'] as num).toDouble(),
    deviceId: json['deviceId'] as String,
    gender: json['gender'] as String,
    status: json['status'] as String,
    requestedAt: DateTime.parse(json['requestedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    rescuedAt: json['rescuedAt'] != null
        ? DateTime.parse(json['rescuedAt'] as String)
        : null,
    rescueDisplayUntil: json['rescueDisplayUntil'] != null
        ? DateTime.parse(json['rescueDisplayUntil'] as String)
        : null,
    remainingSeconds: (json['remainingSeconds'] as num).toInt(),
  );
}

class ActiveMarker {
  final int requestId;
  final int toiletId;
  final double toiletLat;
  final double toiletLng;
  final String displayType; // PAPER_FLYING | RESCUED
  final String gender;
  final int remainingSeconds;

  const ActiveMarker({
    required this.requestId,
    required this.toiletId,
    required this.toiletLat,
    required this.toiletLng,
    required this.displayType,
    required this.gender,
    required this.remainingSeconds,
  });

  bool get isPaperFlying => displayType == 'PAPER_FLYING';
  bool get isRescued => displayType == 'RESCUED';

  factory ActiveMarker.fromJson(Map<String, dynamic> json) => ActiveMarker(
    requestId: (json['requestId'] as num).toInt(),
    toiletId: (json['toiletId'] as num).toInt(),
    toiletLat: (json['toiletLat'] as num).toDouble(),
    toiletLng: (json['toiletLng'] as num).toDouble(),
    displayType: json['displayType'] as String,
    gender: json['gender'] as String,
    remainingSeconds: (json['remainingSeconds'] as num).toInt(),
  );
}
