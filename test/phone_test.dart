import 'package:earthi_naturals/core/utils/phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeIndianPhone strips formatting and the country code', () {
    expect(normalizeIndianPhone('+91 98765 43210'), '9876543210');
    expect(normalizeIndianPhone('098765-43210'), '9876543210');
    expect(normalizeIndianPhone('(91) 98765 43210'), '9876543210');
    expect(normalizeIndianPhone('9876543210'), '9876543210');
  });

  test('normalizeIndianPhone rejects anything that is not a mobile number', () {
    expect(normalizeIndianPhone(null), isNull);
    expect(normalizeIndianPhone(''), isNull);
    expect(normalizeIndianPhone('12345'), isNull);
    expect(normalizeIndianPhone('5876543210'), isNull); // must start 6-9
    expect(normalizeIndianPhone('98765 4321'), isNull); // 9 digits
  });

  test('razorpayContact formats as +91 and 10 digits', () {
    expect(razorpayContact('98765 43210'), '+919876543210');
    expect(razorpayContact('+91 98765 43210'), '+919876543210');
    expect(razorpayContact('abc'), isNull);
  });

  test('validateIndianPhone gives form messages', () {
    expect(validateIndianPhone(''), 'Phone number is required');
    expect(validateIndianPhone('123'), isNotNull);
    expect(validateIndianPhone('+91 90000 11111'), isNull);
  });
}
