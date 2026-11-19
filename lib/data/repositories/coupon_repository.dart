import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../models/coupon.dart';
import '../models/product.dart';

class CouponRepository {
  CouponRepository(this._api);
  final ApiClient _api;

  /// Offers the customer can pick from.
  Future<List<Coupon>> fetchAll() async {
    final data = await _api.get('/coupons');
    return (data as List)
        .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Checks [code] against the cart on the server. Returns the coupon if it can
  /// be used; throws [ApiException] whose message is ready to show (invalid,
  /// expired, cart too small, ...).
  Future<Coupon> validate(String code, List<CartItem> items) async {
    final data = await _api.post('/coupons/validate', {
      'code': code,
      'items': items
          .map((i) => {
                'productSlug': i.product.id,
                'size': i.size,
                'qty': i.qty,
              })
          .toList(),
    });
    return Coupon.fromJson(
        (data as Map<String, dynamic>)['coupon'] as Map<String, dynamic>);
  }
}

final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepository(ref.watch(apiClientProvider)),
);

/// The offers list for the "View offers" sheet.
final availableCouponsProvider = FutureProvider.autoDispose<List<Coupon>>(
  (ref) => ref.watch(couponRepositoryProvider).fetchAll(),
);
