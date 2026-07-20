import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../models/order.dart';
import '../models/payment_session.dart';

/// Drives the Razorpay checkout: ask the backend for an order, open the sheet,
/// then send the result back for verification.
///
/// The app never computes the amount and never holds the key secret — it only
/// relays what the server decided. An order is not real until [verify] returns.
class PaymentRepository {
  PaymentRepository(this._api);
  final ApiClient _api;

  /// Step 1 — price the cart server-side and open a Razorpay order for it.
  /// Only *what* is being bought is sent; prices come from the database.
  Future<PaymentSession> startCheckout(List<OrderItem> items) async {
    final data = await _api.post('/payments/order', {
      'items': items
          .map((i) => {
                'productSlug': i.productSlug,
                'size': i.size,
                'qty': i.qty,
              })
          .toList(),
    });
    return PaymentSession.fromJson(data as Map<String, dynamic>);
  }

  /// Step 2 — show the payment sheet and wait for it to settle.
  ///
  /// Razorpay reports through event callbacks rather than a Future, so this
  /// bridges them onto one. Throws [PaymentCancelled] if the user backs out or
  /// the payment fails.
  Future<PaymentResult> presentCheckout(
    PaymentSession session, {
    String? contact,
    String? email,
  }) {
    final razorpay = Razorpay();
    final completer = Completer<PaymentResult>();

    // Guards against a double callback completing an already-settled Future,
    // which would throw instead of surfacing the real outcome.
    void finish(FutureOr<void> Function() action) {
      if (completer.isCompleted) return;
      action();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      finish(() => completer.complete(PaymentResult(
            razorpayOrderId: r.orderId ?? session.razorpayOrderId,
            razorpayPaymentId: r.paymentId ?? '',
            signature: r.signature ?? '',
          )));
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      // Code 2 is the user dismissing the sheet — not an error worth alarming
      // them about, so it gets softer wording than a real decline.
      final cancelled = r.code == Razorpay.PAYMENT_CANCELLED;
      finish(() => completer.completeError(PaymentCancelled(cancelled
          ? 'Payment cancelled.'
          : (r.message?.isNotEmpty == true
              ? r.message!
              : 'Payment failed. You have not been charged.'))));
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      // The user left for a wallet app; we get no signature, so treat it as
      // unsettled. The webhook still records the payment if it goes through.
      finish(() => completer.completeError(
          PaymentCancelled('Payment is being completed in another app.')));
    });

    razorpay.open({
      'key': session.keyId,
      'order_id': session.razorpayOrderId,
      'amount': session.amount,
      'currency': session.currency,
      'name': 'Earthi Naturals',
      'description': 'Order ${session.reference}',
      if (contact != null && contact.isNotEmpty || email != null && email.isNotEmpty)
        'prefill': {
          if (contact != null && contact.isNotEmpty) 'contact': contact,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      'theme': {'color': '#4C7A45'},
    });

    // `clear()` detaches the event listeners; skipping it leaks a handler per
    // checkout and the next payment fires stale callbacks.
    return completer.future.whenComplete(razorpay.clear);
  }

  /// Step 3 — hand the signature to the backend, which is the only party that
  /// can validate it. Returns the confirmed order.
  Future<Order> verify(PaymentResult result) async {
    final data = await _api.post('/payments/verify', {
      'razorpay_order_id': result.razorpayOrderId,
      'razorpay_payment_id': result.razorpayPaymentId,
      'razorpay_signature': result.signature,
    });
    return Order.fromJson(data as Map<String, dynamic>);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(apiClientProvider)),
);
