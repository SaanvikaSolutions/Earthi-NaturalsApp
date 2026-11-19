import 'dart:math' as math;

/// A discount code, as described by the backend (see server/src/services/coupons.js).
///
/// The server decides whether a code is valid and has the final say on the
/// amount. The app keeps the rules so the discount can follow the cart as items
/// are added or removed without another round trip.
class Coupon {
  final String code;
  final String title;

  /// 'percent' | 'flat' | 'freeship'
  final String type;
  final int value;
  final int? maxDiscount;
  final int minCart;
  final DateTime? expiresAt;

  const Coupon({
    required this.code,
    required this.title,
    required this.type,
    required this.value,
    this.maxDiscount,
    required this.minCart,
    this.expiresAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'flat',
        value: (json['value'] as num?)?.round() ?? 0,
        maxDiscount: (json['maxDiscount'] as num?)?.round(),
        minCart: (json['minCart'] as num?)?.round() ?? 0,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'].toString())
            : null,
      );

  /// Whether a cart worth [subtotal] rupees is big enough for this coupon.
  bool isEligible(int subtotal) => subtotal >= minCart;

  /// What a cart is missing to qualify, or 0 if it already does.
  int shortfall(int subtotal) => math.max(0, minCart - subtotal);

  /// Rupees saved on a cart of [subtotal] with [deliveryFee] delivery.
  /// Mirrors `applyCoupon` on the server; 0 if the cart is below the minimum.
  int discountFor(int subtotal, int deliveryFee) {
    if (!isEligible(subtotal)) return 0;
    var d = switch (type) {
      'percent' => subtotal * value ~/ 100,
      'freeship' => deliveryFee,
      _ => value,
    };
    if (type == 'percent' && maxDiscount != null) d = math.min(d, maxDiscount!);
    // Never discount the goods to nothing (Razorpay rejects a ₹0 order), and a
    // free-delivery coupon can only waive the delivery fee.
    final ceiling = type == 'freeship' ? deliveryFee : math.max(subtotal - 1, 0);
    return d.clamp(0, ceiling).toInt();
  }
}
