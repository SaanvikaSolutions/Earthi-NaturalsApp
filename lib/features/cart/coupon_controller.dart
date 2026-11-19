import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/coupon.dart';
import 'cart_controller.dart';

/// The coupon the customer has applied to the cart, or null.
class CouponController extends Notifier<Coupon?> {
  @override
  Coupon? build() => null;

  void apply(Coupon coupon) => state = coupon;
  void remove() => state = null;
}

final couponProvider =
    NotifierProvider<CouponController, Coupon?>(CouponController.new);

/// Every number the cart and checkout screens show, in one place so they can't
/// disagree. The amount actually charged is still decided by the server.
class OrderSummary {
  final int cartTotal; // sum of selling prices
  final int mrpDiscount; // MRP minus selling price
  final int deliveryFee;
  final int couponDiscount; // 0 when no coupon applies
  final Coupon? coupon; // only set while the cart still qualifies for it
  final String? couponProblem; // why an applied coupon stopped applying

  const OrderSummary({
    required this.cartTotal,
    required this.mrpDiscount,
    required this.deliveryFee,
    required this.couponDiscount,
    this.coupon,
    this.couponProblem,
  });

  int get grandTotal => cartTotal + deliveryFee - couponDiscount;
}

final orderSummaryProvider = Provider<OrderSummary>((ref) {
  final cart = ref.watch(cartProvider);
  final applied = ref.watch(couponProvider);

  final cartTotal = cart.fold<int>(0, (s, i) => s + i.product.price * i.qty);
  final mrpTotal = cart.fold<int>(0, (s, i) => s + i.product.mrp * i.qty);
  final deliveryFee = cart.isEmpty ? 0 : CartController.deliveryFeeRupees;

  // An applied coupon quietly stops applying if the cart drops below its
  // minimum (item removed, quantity lowered) — say so rather than keep a
  // discount the server would refuse.
  Coupon? active;
  String? problem;
  if (applied != null) {
    if (applied.isEligible(cartTotal)) {
      active = applied;
    } else {
      problem = '${applied.code} needs a cart of ₹${applied.minCart} — '
          'add ₹${applied.shortfall(cartTotal)} more to use it.';
    }
  }

  return OrderSummary(
    cartTotal: cartTotal,
    mrpDiscount: mrpTotal - cartTotal,
    deliveryFee: deliveryFee,
    couponDiscount: active?.discountFor(cartTotal, deliveryFee) ?? 0,
    coupon: active,
    couponProblem: problem,
  );
});
