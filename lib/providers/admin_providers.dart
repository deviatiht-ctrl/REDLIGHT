import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_order.dart';
import '../models/product.dart';
import 'core_providers.dart';

/// Admin: tout pwodwi (pa filtè).
final adminProductsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productServiceProvider).fetchProducts(),
);

/// Admin: tout kòmand.
final adminOrdersProvider = FutureProvider<List<AppOrder>>(
  (ref) => ref.watch(orderServiceProvider).fetchAllOrders(),
);

class AdminStats {
  final int productCount;
  final int ordersToday;
  final double totalRevenue;
  final int pendingOrders;

  const AdminStats({
    required this.productCount,
    required this.ordersToday,
    required this.totalRevenue,
    required this.pendingOrders,
  });
}

/// Estatistik dashboard: kantite pwodwi, kòmand jodi a, total vant.
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final products = await ref.watch(adminProductsProvider.future);
  final orders = await ref.watch(adminOrdersProvider.future);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final ordersToday = orders
      .where((o) {
        final d = o.createdAt?.toLocal();
        return d != null && !d.isBefore(today);
      })
      .length;

  final revenue = orders
      .where((o) => o.paymentStatus == 'paid')
      .fold(0.0, (sum, o) => sum + o.total);

  return AdminStats(
    productCount: products.length,
    ordersToday: ordersToday,
    totalRevenue: revenue,
    pendingOrders: orders.where((o) => o.status == 'pending').length,
  );
});
