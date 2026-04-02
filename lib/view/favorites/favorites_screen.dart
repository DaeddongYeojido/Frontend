import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../provider/favorite_provider.dart';
import '../../data/model/favorite_toilet.dart';
import '../../data/model/toilet_summary.dart';
import '../widget/open_status_badge.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('즐겨찾기',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: false,
      ),
      body: favorites.isEmpty
          ? const _Empty()
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: favorites.length,
              itemBuilder: (_, i) => _Card(toilet: favorites[i]),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite_border,
              size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('즐겨찾기한 화장실이 없어요.',
              style: TextStyle(
                  fontSize: 15, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('화장실 상세에서 하트를 눌러 추가해보세요.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      );
}

class _Card extends ConsumerWidget {
  final FavoriteToilet toilet;
  const _Card({required this.toilet});

  ToiletSummary _toSummary(FavoriteToilet f) => ToiletSummary(
        id: f.id,
        name: f.name,
        address: f.address,
        lat: f.lat,
        lng: f.lng,
        openStatus: f.openStatus,
        isDisabled: f.isDisabled,
        isGenderSep: f.isGenderSep,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.wc,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),

            // 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름
                  Text(toilet.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),

                  // 주소
                  Text(toilet.address,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),

                  // 상태 배지 + 태그들
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OpenStatusBadge(status: toilet.openStatus),
                      if (toilet.isDisabled)
                        _TagChip(
                            icon: Icons.accessible,
                            label: '장애인 화장실'),
                      if (toilet.isGenderSep)
                        _TagChip(icon: Icons.wc, label: '남녀 구분'),
                    ],
                  ),
                ],
              ),
            ),

            // 즐겨찾기 해제 버튼
            GestureDetector(
              onTap: () => ref
                  .read(favoriteProvider.notifier)
                  .toggle(_toSummary(toilet)),
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.favorite, color: Colors.red, size: 22),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.filterBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
