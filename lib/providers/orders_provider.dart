import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_order.dart';
import '../models/order_tracking.dart';
import 'core_providers.dart';

/// Kòmand itilizatè konekte a.
final myOrdersProvider = FutureProvider<List<AppOrder>>((ref) async {
  if (ref.watch(currentUserProvider) == null) return const [];
  return ref.watch(orderServiceProvider).fetchMyOrders();
});

/// Swivi (pozisyon + ETA + istorik) pou yon kòmand.
final orderTrackingProvider =
    FutureProvider.family<OrderTrackingInfo, String>(
  (ref, orderId) =>
      ref.watch(orderServiceProvider).fetchTracking(orderId),
);
