class Review {
  final int id;
  final int toiletId;
  final String deviceId;
  final int rating;
  final String? content;
  final String? imageUrl; // ← 추가
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.toiletId,
    required this.deviceId,
    required this.rating,
    this.content,
    this.imageUrl, // ← 추가
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: (json['id'] as num).toInt(),
        toiletId: (json['toiletId'] as num).toInt(),
        deviceId: json['deviceId'] as String,
        rating: (json['rating'] as num).toInt(),
        content: json['content'] as String?,
        imageUrl: json['imageUrl'] as String?, // ← 추가
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class ReviewPage {
  final List<Review> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final bool last;

  const ReviewPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.last,
  });

  factory ReviewPage.fromJson(Map<String, dynamic> json) {
    final page = json['page'] as Map<String, dynamic>? ?? {};
    return ReviewPage(
      content: (json['content'] as List)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (page['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (page['totalPages'] as num?)?.toInt() ?? 0,
      number: (page['number'] as num?)?.toInt() ?? 0,
      last: (page['number'] as num?)?.toInt() == ((page['totalPages'] as num?)?.toInt() ?? 1) - 1,
    );
  }
}
