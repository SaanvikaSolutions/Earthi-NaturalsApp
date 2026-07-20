/// A single line in an order.
class OrderItem {
  final String productSlug;
  final String name;
  final String size;
  final int qty;
  final int price;

  const OrderItem({
    required this.productSlug,
    required this.name,
    required this.size,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'productSlug': productSlug,
        'name': name,
        'size': size,
        'qty': qty,
        'price': price,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productSlug: json['productSlug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: json['size'] as String? ?? '',
      qty: (json['qty'] as num?)?.round() ?? 1,
      price: (json['price'] as num?)?.round() ?? 0,
    );
  }
}

/// A placed order, mirroring the API shape (see server/src/models/Order.js).
class Order {
  final String id;
  final String reference;
  final String status;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.reference,
    required this.status,
    required this.items,
    this.subtotal = 0,
    this.deliveryFee = 0,
    required this.total,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      status: json['status'] as String? ?? 'Placed',
      items: (json['items'] as List?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subtotal: (json['subtotal'] as num?)?.round() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.round() ?? 0,
      total: (json['total'] as num?)?.round() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
