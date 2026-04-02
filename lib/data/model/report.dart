enum ReportStatus { pending, approved, rejected }

extension ReportStatusExt on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pending:  return '검토중';
      case ReportStatus.approved: return '승인됨';
      case ReportStatus.rejected: return '반려됨';
    }
  }

  String get apiValue {
    switch (this) {
      case ReportStatus.pending:  return 'PENDING';
      case ReportStatus.approved: return 'APPROVED';
      case ReportStatus.rejected: return 'REJECTED';
    }
  }

  static ReportStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'APPROVED': return ReportStatus.approved;
      case 'REJECTED': return ReportStatus.rejected;
      default:         return ReportStatus.pending;
    }
  }
}

class Report {
  final int id;
  final String deviceId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? openStatus;
  final bool? isDisabled;
  final bool? isGenderSep;
  final String? openHours;
  final String? memo;
  final String? imageUrl;
  final ReportStatus status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.openStatus,
    this.isDisabled,
    this.isGenderSep,
    this.openHours,
    this.memo,
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    id:         (json['id'] as num).toInt(),
    deviceId:   json['deviceId'] as String,
    name:       json['name'] as String,
    address:    json['address'] as String,
    lat:        (json['lat'] as num).toDouble(),
    lng:        (json['lng'] as num).toDouble(),
    openStatus: json['openStatus'] as String?,
    isDisabled: json['isDisabled'] as bool?,
    isGenderSep:json['isGenderSep'] as bool?,
    openHours:  json['openHours'] as String?,
    memo:       json['memo'] as String?,
    imageUrl:   json['imageUrl'] as String?,
    status:     ReportStatusExt.fromString(json['status'] as String? ?? 'PENDING'),
    createdAt:  DateTime.parse(json['createdAt'] as String),
  );
}
