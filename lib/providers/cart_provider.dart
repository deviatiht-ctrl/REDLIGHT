import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'core_providers.dart';

/// Panyen an — persiste nan shared_preferences, resolve pwodwi via Supabase.
class CartNotifier extends AsyncNotifier<List<CartItem>> {
  @override
  Future<List<CartItem>> build() async {
    final raw = ref.watch(localStoreProvider).cartItems;
    if (raw.isEmpty) return const [];

    final ids = raw.map((e) => e['product_id'] as String).toList();
    try {
      final products = await ref.read(productServiceProvider).fetchByIds(ids);
      final byId = {for (final p in products) p.id: p};
      return [
        for (final e in raw)
          if (byId.containsKey(e['product_id']))
            CartItem(
              product: byId[e['product_id']]!,
              quantity: (e['quantity'] as num? ?? 1).toInt(),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(Product product, {int quantity = 1}) async {
    final current = [...state.value ?? const <CartItem>[]];
    final index = current.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      final maxQty = product.stock > 0 ? product.stock : 999;
      final newQty = (current[index].quantity + quantity).clamp(1, maxQty);
      current[index] = current[index].copyWith(quantity: newQty);
    } else {
      current.add(CartItem(product: product, quantity: quantity));
    }
    await _save(current);
  }

  Future<void> setQuantity(String productId, int quantity) async {
    final current = [...state.value ?? const <CartItem>[]];
    if (quantity <= 0) {
      current.removeWhere((e) => e.product.id == productId);
    } else {
      final index = current.indexWhere((e) => e.product.id == productId);
      if (index < 0) return;
      final maxQty = current[index].product.stock;
      final clamped = maxQty > 0 ? quantity.clamp(1, maxQty) : quantity;
      current[index] = current[index].copyWith(quantity: clamped);
    }
    await _save(current);
  }

  Future<void> remove(String productId) async {
    final current = [...state.value ?? const <CartItem>[]]
      ..removeWhere((e) => e.product.id == productId);
    await _save(current);
  }

  Future<void> clear() => _save(const []);

  Future<void> _save(List<CartItem> items) async {
    state = AsyncData(items);
    await ref
        .read(localStoreProvider)
        .saveCart(items.map((e) => e.toJson()).toList());
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider).value ?? const <CartItem>[];
  return items.fold<double>(0, (sum, e) => sum + e.lineTotal);
});

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider).value ?? const <CartItem>[];
  return items.fold<int>(0, (sum, e) => sum + e.quantity);
});
