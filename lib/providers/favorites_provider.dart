import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'core_providers.dart';

/// Favori — lis id pwodwi, persiste lokalman.
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(localStoreProvider).favorites;

  Future<void> toggle(String productId) async {
    final next = {...state};
    if (!next.remove(productId)) next.add(productId);
    state = next;
    await ref.read(localStoreProvider).saveFavorites(next);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

/// Pwodwi favori yo (resolve id → Product).
final favoriteProductsProvider = FutureProvider<List<Product>>((ref) async {
  final ids = ref.watch(favoritesProvider).toList();
  if (ids.isEmpty) return const [];
  return ref.watch(productServiceProvider).fetchByIds(ids);
});
