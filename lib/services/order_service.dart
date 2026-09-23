import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_order.dart';
import '../models/cart_item.dart';

/// Sèvis kòmand — placeOrder pase pa fonksyon SQL `place_order`
/// (atomik: order + items + degrese stock nan yon sèl tranzaksyon).
class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;

  static const _selectWithItems =
      '*, order_items(*, products(name, images))';

  Future<String> placeOrder({
    required List<CartItem> items,
    required String checkoutKey,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final payload = items
        .map(
          (e) => {
            'product_id': e.product.id,
            'quantity': e.quantity,
          },
        )
        .toList();

    final orderId = await _client.rpc(
      'checkout_order',
      params: {
        'p_items': payload,
        'p_checkout_key': checkoutKey,
        'p_delivery_address': deliveryAddress,
        'p_payment_method': paymentMethod,
      },
    );
    return orderId as String;
  }

  Future<List<AppOrder>> fetchMyOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final data = await _client
        .from('orders')
        .select(_selectWithItems)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => AppOrder.fromJson(e)).toList();
  }

  /// Admin: tout kòmand.
  Future<List<AppOrder>> fetchAllOrders() async {
    final data = await _client
        .from('orders')
        .select(_selectWithItems)
        .order('created_at', ascending: false);
    return data.map((e) => AppOrder.fromJson(e)).toList();
  }

  /// Kliyan: kansèle yon kòmand "pending" (RLS la verifye sa).
  Future<void> cancelOrder(String orderId) => updateStatus(orderId, 'cancelled');

  /// Admin: chanje estati nenpòt kòmand.
  Future<void> updateStatus(String orderId, String status) async {
    await _client.rpc('change_order_status', params: {'p_order_id': orderId, 'p_status': status});
  }
}
