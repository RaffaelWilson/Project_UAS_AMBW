import 'sparepart.dart';

class CartItem {
  final Sparepart sparepart;
  int quantity;

  CartItem({
    required this.sparepart,
    this.quantity = 1,
  });

  double get totalPrice => sparepart.price * quantity;
}
