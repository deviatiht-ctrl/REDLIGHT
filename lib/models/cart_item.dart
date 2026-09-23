import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get lineTotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) => CartItem(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toJson() => {
    'product_id': product.id,
    'quantity': quantity,
  };
}
