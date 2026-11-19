import 'package:earthi_naturals/data/models/coupon.dart';
import 'package:flutter_test/flutter_test.dart';

Coupon _c(String type, int value, int min, {int? cap}) => Coupon(
    code: 'X', title: '', type: type, value: value, minCart: min, maxDiscount: cap);

void main() {
  const fee = 69;

  test('WELCOME10: 10% off up to 100, min 499', () {
    final c = _c('percent', 10, 499, cap: 100);
    expect(c.discountFor(498, fee), 0); // below minimum
    expect(c.discountFor(499, fee), 49);
    expect(c.discountFor(2000, fee), 100); // capped
  });

  test('EARTHI50: flat 50, min 399', () {
    final c = _c('flat', 50, 399);
    expect(c.discountFor(398, fee), 0);
    expect(c.discountFor(399, fee), 50);
  });

  test('NATURAL15: 15% off up to 200, min 999', () {
    final c = _c('percent', 15, 999, cap: 200);
    expect(c.discountFor(999, fee), 149);
    expect(c.discountFor(5000, fee), 200);
  });

  test('FREESHIP waives exactly the delivery fee, min 299', () {
    final c = _c('freeship', 0, 299);
    expect(c.discountFor(298, fee), 0);
    expect(c.discountFor(299, fee), 69);
    expect(c.discountFor(299, 0), 0); // nothing to waive on an empty cart
  });

  test('FESTIVE100: flat 100, min 1299', () {
    final c = _c('flat', 100, 1299);
    expect(c.discountFor(1298, fee), 0);
    expect(c.discountFor(1299, fee), 100);
  });

  test('shortfall says how much more the cart needs', () {
    final c = _c('flat', 100, 1299);
    expect(c.shortfall(1000), 299);
    expect(c.shortfall(1299), 0);
  });
}
