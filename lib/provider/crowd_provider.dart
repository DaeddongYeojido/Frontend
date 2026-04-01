import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/crowd_vote.dart';
import '../data/repository/crowd_repository.dart';
import '../core/utils/device_id_util.dart';

final crowdRepositoryProvider = Provider((ref) => CrowdRepository());

class CrowdVoteNotifier extends AsyncNotifier<Map<int, CrowdVote>> {
  @override
  Future<Map<int, CrowdVote>> build() async => {};

  Future<void> vote(int toiletId, String level) async {
    final previous = state.value ?? {};
    state = const AsyncLoading();

    final deviceId = await DeviceIdUtil.getDeviceId();
    final result = await AsyncValue.guard(
      () => ref.read(crowdRepositoryProvider)
          .vote(toiletId: toiletId, deviceId: deviceId, level: level),
    );

    result.when(
      data: (vote) {
        state = AsyncData({...previous, toiletId: vote});
      },
      error: (e, st) {
        state = AsyncData(previous);
      },
      loading: () {},
    );
  }

  CrowdVote? getVoteFor(int toiletId) {
    final vote = state.value?[toiletId];
    return (vote == null || vote.isExpired) ? null : vote;
  }
}

final crowdVoteProvider =
    AsyncNotifierProvider<CrowdVoteNotifier, Map<int, CrowdVote>>(
  CrowdVoteNotifier.new,
);
