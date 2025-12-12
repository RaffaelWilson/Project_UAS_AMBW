class Order {
  final int id;
  final String userId;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      total: (json['total'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total': total,
      'status': status,
    };
  }
}

class OrderItem {
  final int orderId;
  final int sparepartId;
  final int quantity;
  final String? sparepartName;
  final double? sparepartPrice;

  OrderItem({
    required this.orderId,
    required this.sparepartId,
    required this.quantity,
    this.sparepartName,
    this.sparepartPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderId: json['order_id'],
      sparepartId: json['sparepart_id'],
      quantity: json['quantity'],
      sparepartName: json['sparepart_name'],
      sparepartPrice: json['sparepart_price'] != null 
          ? (json['sparepart_price'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'sparepart_id': sparepartId,
      'quantity': quantity,
    };
  }
}