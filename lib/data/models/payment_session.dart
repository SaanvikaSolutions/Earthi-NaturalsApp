/// What the backend hands back when a checkout is started.
///
/// Everything that decides the amount is computed server-side; the app just
/// relays these values to the Razorpay sheet. Note [keyId] is the *public* key
/// — the secret stays on the server and never reaches the device.
class PaymentSession {
  final String orderId; // our order's id
  final String reference; // human-facing, e.g. "EN042317"
  final String razorpayOrderId;
  final int amount; // paise, as Razorpay expects
  final String currency;
  final String keyId;
  final int subtotal;
  final int deliveryFee;
  final int total; // rupees, for display

  const PaymentSession({
    required this.orderId,
    required this.reference,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    return PaymentSession(
      orderId: json['orderId'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      amount: (json['amount'] as num?)?.round() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['keyId'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.round() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.round() ?? 0,
      total: (json['total'] as num?)?.round() ?? 0,
    );
  }
}

/// The three fields Razorpay returns on success, forwarded to the backend so it
/// can check the signature. Nothing here is trusted until it does.
class PaymentResult {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String signature;

  const PaymentResult({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.signature,
  });
}

/// Raised when the sheet closes without a successful payment — user cancelled,
/// card declined, network dropped.
class PaymentCancelled implements Exception {
  final String message;
  PaymentCancelled(this.message);
  @override
  String toString() => message;
}
