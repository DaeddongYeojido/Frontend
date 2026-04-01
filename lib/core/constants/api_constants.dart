class ApiConstants {
  static const String baseUrl = 'http://192.168.219.105:8080'; // Android 에뮬레이터
  // iOS 시뮬레이터: 'http://localhost:8080'
  // 실기기: 'http://[PC IP]:8080'
  // 배포 후: GCP Cloud Run URL

  static const String nearby   = '/api/v1/toilets/nearby';
  static const String nearest  = '/api/v1/toilets/nearest';
  static String detail(int id) => '/api/v1/toilets/$id';
  static String crowd(int id)  => '/api/v1/toilets/$id/crowd';
  static String reviews(int id)         => '/api/v1/toilets/$id/reviews';
  static String deleteReview(int toiletId, int reviewId)
  => '/api/v1/toilets/$toiletId/reviews/$reviewId';
}
