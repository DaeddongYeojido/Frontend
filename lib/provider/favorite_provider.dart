import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/favorite_toilet.dart';
import '../data/model/toilet_summary.dart';
import '../data/repository/favorite_repository.dart';

final favoriteRepositoryProvider = Provider((ref) => FavoriteRepository());

class FavoriteNotifier extends Notifier<List<FavoriteToilet>> {
  @override
  List<FavoriteToilet> build() =>
      ref.read(favoriteRepositoryProvider).getAll();

  bool isFavorite(int id) =>
      ref.read(favoriteRepositoryProvider).isFavorite(id);

  Future<void> toggle(ToiletSummary toilet) async {
    final repo = ref.read(favoriteRepositoryProvider);
    if (repo.isFavorite(toilet.id)) {
      await repo.remove(toilet.id);
    } else {
      await repo.add(toilet);
    }
    state = repo.getAll();
  }
}

final favoriteProvider =
NotifierProvider<FavoriteNotifier, List<FavoriteToilet>>(
  FavoriteNotifier.new,
);
