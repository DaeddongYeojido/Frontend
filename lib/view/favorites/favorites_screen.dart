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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      Icon(Icons.favorite_border, size: 56, color: AppColors.textHint),
      SizedBox(height: 12),
      Text('즐겨찾기한 화장실이 없어요.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
      SizedBox(height: 4),
      Text('화장실 상세에서 하트를 눌러 추가해보세요.',
          style: TextStyle(fontSize: 12, color: AppColors.textHint)),
    ]),
  );
}

class _Card extends ConsumerWidget {
  final FavoriteToilet toilet;
  const _Card({required this.toilet});

  ToiletSummary _toSummary(FavoriteToilet f) => ToiletSummary(
    id: f.id, name: f.name, address: f.address,
    lat: f.lat, lng: f.lng, openStatus: f.openStatus,
    isDisabled: f.isDisabled, isGenderSep: f.isGenderSep,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.wc, color: AppColors.primary, size: 22),
        ),
        title: Text(toilet.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(toilet.address,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            OpenStatusBadge(status: toilet.openStatus),
          ]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
          onPressed: () =>
              ref.read(favoriteProvider.notifier).toggle(_toSummary(toilet)),
        ),
      ),
    );
  }
}
