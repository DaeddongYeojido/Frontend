import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/paper_request.dart';
import '../data/repository/paper_request_repository.dart';
import '../core/utils/device_id_util.dart';
import '../core/network/dio_client.dart';

final paperRequestRepositoryProvider =
Provider((ref) => PaperRequestRepository());

// ── 지도 마커 폴링 (10초마다) ──────────────────────────────────────────────

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

// ── 내 요청 상태 관리 ─────────────────────────────────────────────────────

class PaperRequestNotifier extends AsyncNotifier<PaperRequest?> {
  Timer? _timer;

  @override
  Future<PaperRequest?> build() async {
    ref.onDispose(_stopPolling);
    return null;
  }

  /// 성공 시 null, 실패 시 에러 메시지 반환
  Future<String?> createRequest({
    required int toiletId,
    required String gender,
    required double lat,
    required double lng,
  }) async {
    final deviceId = await DeviceIdUtil.getDeviceId();

    final result = await AsyncValue.guard(() async {
      return ref.read(paperRequestRepositoryProvider).createRequest(
        toiletId: toiletId,
        deviceId: deviceId,
        gender: gender,
        lat: lat,
        lng: lng,
      );
    });

    state = result;

    if (result.hasError) {
      return extractErrorMessage(result.error,
          fallback: '휴지 요청에 실패했습니다.');
    }

    result.whenData((pr) {
      if (pr != null) _startPolling(pr.id, deviceId);
    });
    return null;
  }

  /// 성공 시 null, 실패 시 에러 메시지 반환
  Future<String?> rescue() async {
    final current = state.value;
    if (current == null) return null;

    final deviceId = await DeviceIdUtil.getDeviceId();
    final result = await AsyncValue.guard(() async {
      return ref.read(paperRequestRepositoryProvider).rescue(
        requestId: current.id,
        deviceId: deviceId,
      );
    });

    state = result;
    _stopPolling();

    if (result.hasError) {
      return extractErrorMessage(result.error,
          fallback: '구조 완료 처리에 실패했습니다.');
    }
    return null;
  }

  void clear() {
    _stopPolling();
    state = const AsyncData(null);
  }

  void _startPolling(int requestId, String deviceId) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) async {
      try {
        final updated = await ref
            .read(paperRequestRepositoryProvider)
            .getStatus(requestId: requestId, deviceId: deviceId);
        state = AsyncData(updated);
        if (!updated.isActive) _stopPolling();
      } catch (_) {
        // 폴링 실패는 조용히 무시 (다음 주기에 재시도)
      }
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
