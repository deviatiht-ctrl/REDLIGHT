import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_order.dart';
import 'core_providers.dart';

/// Kòmand itilizatè konekte a.
final myOrdersProvider = FutureProvider<List<AppOrder>>((ref) async {
  if (ref.watch(currentUserProvider) == null) return const [];
  return ref.watch(orderServiceProvider).fetchMyOrders();
});
