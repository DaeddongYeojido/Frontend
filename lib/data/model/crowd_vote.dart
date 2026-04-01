class CrowdVote {
  final int toiletId;
  final String deviceId;
  final String level;
  final DateTime votedAt;
  final DateTime expiresAt;

  const CrowdVote({
    required this.toiletId,
    required this.deviceId,
    required this.level,
    required this.votedAt,
    required this.expiresAt,
  });

  factory CrowdVote.fromJson(Map<String, dynamic> json) => CrowdVote(
    toiletId: (json['toiletId'] as num).toInt(),
    deviceId: json['deviceId'] as String,
    level: json['level'] as String,
    votedAt: DateTime.parse(json['votedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
