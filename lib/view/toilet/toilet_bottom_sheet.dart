import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/toilet_provider.dart';
import '../../provider/favorite_provider.dart';
import '../../data/model/toilet_detail.dart';
import '../../data/model/toilet_summary.dart';
import '../widget/open_status_badge.dart';
import '../widget/crowded_button.dart';
import '../widget/review_popup.dart';

class ToiletBottomSheet extends ConsumerWidget {
  final int toiletId;
  final VoidCallback? onDismiss;
  const ToiletBottomSheet({super.key, required this.toiletId, this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(toiletDetailProvider(toiletId));

    return GestureDetector(
      // ③ 아래로 스와이프하면 닫기
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          onDismiss?.call();
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: detailAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (e, _) => SizedBox(
            height: 180,
            child: Center(
              child: Text('불러오지 못했어요.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          data: (detail) => _Content(detail: detail, onDismiss: onDismiss),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final ToiletDetail detail;
  final VoidCallback? onDismiss;
  const _Content({required this.detail, this.onDismiss});

  void _openReview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewPopup(toiletId: detail.id, toiletName: detail.name),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);
    final isFav = favorites.any((f) => f.id == detail.id);

    final summary = ToiletSummary(
      id: detail.id, name: detail.name, address: detail.address,
      lat: detail.lat, lng: detail.lng, openStatus: detail.openStatus,
      isDisabled: detail.isDisabled, isGenderSep: detail.isGenderSep,
    );

    return Padding(
      // ④ 상단 패딩을 12→8로 줄여 이름 위 여백 축소
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들 바
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          )),
          // ④ 핸들→이름 간격도 8→6으로 줄임
          const SizedBox(height: 6),

          // 이름 + 붐벼요 버튼: IntrinsicHeight로 버튼은 오른쪽 고정,
          // 왼쪽 정보는 자연스럽게 위로 밀착
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽: 이름 / 운영상태+별점+즐겨찾기 / 주소 / 태그
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 이름
                      Text(detail.name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.2)),
                      const SizedBox(height: 6),

                      // 운영상태 + 별점 + 즐겨찾기
                      Row(
                        children: [
                          OpenStatusBadge(status: detail.openStatus),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openReview(context),
                            child: Row(children: [
                              const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                              const SizedBox(width: 2),
                              Text(detail.ratingDisplay,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const SizedBox(width: 2),
                              Text('(${detail.reviewCount})',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ]),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                ref.read(favoriteProvider.notifier).toggle(summary),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : AppColors.textHint,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 주소
                      Text(detail.address,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 10),

                      // 태그
                      Row(children: [
                        if (detail.isDisabled) ...[
                          _TagChip(icon: Icons.accessible, label: '장애인 화장실'),
                          const SizedBox(width: 8),
                        ],
                        if (detail.isGenderSep)
                          _TagChip(icon: Icons.wc, label: '남녀 구분'),
                      ]),

                      // 운영시간
                      if (detail.openHours != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(detail.openHours!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 오른쪽: 붐벼요 버튼 (상단 고정)
                Align(
                  alignment: Alignment.topCenter,
                  child: CrowdedButton(
                    toiletId: detail.id,
                    crowdedCount: detail.crowdSummary['CROWDED'] ?? 0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 길찾기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${detail.name} 길찾기'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('상세 길찾기',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TagChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.filterBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
