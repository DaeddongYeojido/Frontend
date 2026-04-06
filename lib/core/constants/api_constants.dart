class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8080';

  //'http://10.0.2.2:8080'

  // 화장실
  static const String nearby = '/api/v1/toilets/nearby';
  static const String nearest = '/api/v1/toilets/nearest';
  static String detail(int id) => '/api/v1/toilets/$id';
  static String crowd(int id) => '/api/v1/toilets/$id/crowd';

  // 리뷰
  static String reviews(int id) => '/api/v1/toilets/$id/reviews';
  static String deleteReview(int toiletId, int reviewId) =>
      '/api/v1/toilets/$toiletId/reviews/$reviewId';

  // 제보
  static const String reports = '/api/v1/reports';
  static const String myReports = '/api/v1/reports/my';

  // 휴지 요청 ── 신규 추가
  static const String paperRequests = '/api/v1/paper-requests';
  static const String paperRequestActiveMarkers =
      '/api/v1/paper-requests/active-markers';
  static const String paperRequestFcmToken =
      '/api/v1/paper-requests/fcm-token';
  static String paperRequestRescue(int id) =>
      '/api/v1/paper-requests/$id/rescue';
  static String paperRequestStatus(int id) =>
      '/api/v1/paper-requests/$id/status';
}
