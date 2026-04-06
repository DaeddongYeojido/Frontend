import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/paper_request.dart';
import '../data/repository/paper_request_repository.dart';
import '../core/utils/device_id_util.dart';

final paperRequestRepositoryProvider =
Provider((ref) => PaperRequestRepository());

// ── 지도 마커 폴링 (10초마다) ─────────────────────────────────────────────────

final activeMarkersProvider =
StreamProvider<List<ActiveMarker>>((ref) async* {
  final repo = ref.watch(paperRequestRepositoryProvider);
  while (true) {
    try {
      yield await repo.getActiveMarkers();
    } catch (_) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 10));
  }
});

// ── 내 요청 상태 관리 ──────────────────────────────────────────────────────────

class PaperRequestNotifier extends AsyncNotifier<PaperRequest?> {
  Timer? _timer;

  @override
  Future<PaperRequest?> build() async {
    ref.onDispose(_stopPolling);
    return null;
  }

  /// 휴지 요청 생성
  Future<void> createRequest({
    required int toiletId,
    required String gender,
    required double lat,
    required double lng,
  }) async {
    final deviceId = await DeviceIdUtil.getDeviceId();

    // AsyncLoading 대신 바로 guard로 진행 (Loading 상태에서 .value가 null이 되는 문제 방지)
    final result = await AsyncValue.guard(() async {
      return ref.read(paperRequestRepositoryProvider).createRequest(
        toiletId: toiletId,
        deviceId: deviceId,
        gender: gender,
        lat: lat,
        lng: lng,
      );
    });

    // 성공 시 state 업데이트 후 폴링 시작
    state = result;
    result.whenData((pr) {
      if (pr != null) _startPolling(pr.id, deviceId);
    });
  }

  /// 구조 완료 처리
  Future<void> rescue() async {
    final current = state.value;
    if (current == null) return;

    final deviceId = await DeviceIdUtil.getDeviceId();
    state = await AsyncValue.guard(() async {
      return ref.read(paperRequestRepositoryProvider).rescue(
        requestId: current.id,
        deviceId: deviceId,
      );
    });
    _stopPolling();
  }

  /// 수동 초기화 (만료 후 UI 정리용)
  void clear() {
    _stopPolling();
    state = const AsyncData(null);
  }

  /// 7초마다 서버 상태 폴링 (7분 만료 자동 감지)
  void _startPolling(int requestId, String deviceId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) async {
      try {
        final updated = await ref
            .read(paperRequestRepositoryProvider)
            .getStatus(requestId: requestId, deviceId: deviceId);
        state = AsyncData(updated);
        if (!updated.isActive) _stopPolling();
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }
}

final paperRequestProvider =
AsyncNotifierProvider<PaperRequestNotifier, PaperRequest?>(
  PaperRequestNotifier.new,
);
