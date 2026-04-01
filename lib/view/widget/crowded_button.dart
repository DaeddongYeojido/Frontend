import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/crowd_provider.dart';
import '../../provider/toilet_provider.dart';

class CrowdedButton extends ConsumerWidget {
  final int toiletId;
  final int crowdedCount;

  const CrowdedButton({
    super.key,
    required this.toiletId,
    required this.crowdedCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(crowdVoteProvider).isLoading;
    final isVoted =
        ref.read(crowdVoteProvider.notifier).getVoteFor(toiletId) != null;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
        await ref.read(crowdVoteProvider.notifier).vote(toiletId, 'CROWDED');
        ref.invalidate(toiletDetailProvider(toiletId));
      },
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isVoted
              ? AppColors.crowdedBg.withOpacity(0.7)
              : AppColors.crowdedBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? const Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.white, size: 20),
            const SizedBox(height: 2),
            const Text('BOOM-\nBYEO-YO',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.2)),
            const SizedBox(height: 2),
            Text('$crowdedCount votes',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
