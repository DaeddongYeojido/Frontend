class Review {
  final int id;
  final int toiletId;
  final String deviceId;
  final int rating;
  final String? content;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.toiletId,
    required this.deviceId,
    required this.rating,
    this.content,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: (json['id'] as num).toInt(),
    toiletId: (json['toiletId'] as num).toInt(),
    deviceId: json['deviceId'] as String,
    rating: (json['rating'] as num).toInt(),
    content: json['content'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

// 페이지네이션 래퍼
class ReviewPage {
  final List<Review> content;
  final int totalElements;
  final int totalPages;
  final int number;       // 현재 페이지 (0-based)
  final bool last;

  const ReviewPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.last,
  });

  factory ReviewPage.fromJson(Map<String, dynamic> json) => ReviewPage(
    content: (json['content'] as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalElements: (json['totalElements'] as num).toInt(),
    totalPages: (json['totalPages'] as num).toInt(),
    number: (json['number'] as num).toInt(),
    last: json['last'] as bool,
  );
}
