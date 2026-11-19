import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/api/api_client.dart';
import '../../data/models/order.dart';
import '../../data/models/payment_session.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../cart/coupon_controller.dart';
import '../profile/address_controller.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final summary = ref.watch(orderSummaryProvider);
    final address = ref.watch(selectedAddressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        leading: const BackButton(),
        title: const Text('Select Address & Pay',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.pagePadding),
        children: [
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        address == null
                            ? 'No delivery address'
                            : 'Delivery to ${address.name}'
                                '${address.pincode.isEmpty ? '' : ', ${address.pincode}'}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  address == null
                      ? 'Add an address to continue.'
                      : '${address.line}\n${address.phone}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/addresses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.chipBg,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.input)),
                  ),
                  child: Text(address == null
                      ? 'Add Delivery Address'
                      : 'Change or Edit Address'),
                ),
              ),
            ],
          )),
          const SizedBox(height: 14),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Price Details',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              _priceLine('Cart total (${items.length} items)',
                  '₹${summary.cartTotal}'),
              _priceLine('Discount on MRP', '-₹${summary.mrpDiscount}',
                  color: AppColors.discountText),
              _priceLine('Delivery Fee', '₹${summary.deliveryFee}'),
              if (summary.coupon != null)
                _priceLine('Coupon (${summary.coupon!.code})',
                    '-₹${summary.couponDiscount}',
                    color: AppColors.discountText),
              const Divider(height: 24),
              _priceLine('You Pay', '₹${summary.grandTotal}', bold: true),
              if (summary.couponProblem != null) ...[
                const SizedBox(height: 8),
                Text(summary.couponProblem!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.remove)),
              ],
            ],
          )),
          const SizedBox(height: 14),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Items (${items.length.toString().padLeft(2, '0')})',
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 56,
                          height: 56,
                          child: ProductImage(
                              imageUrl: item.product.imageUrl)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Delivery by Wed, 12 Jul',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.pagePadding),
          child: PrimaryButton(
            label: 'Proceed to Pay',
            icon: Icons.arrow_forward,
            onPressed: items.isEmpty || address == null
                ? null
                : () => _placeOrder(context, ref),
          ),
        ),
      ),
    );
  }

  /// Runs the full Razorpay checkout: create the order server-side, show the
  /// payment sheet, then have the backend verify the signature.
  ///
  /// The amount is never decided here — the server prices the cart from the
  /// database, so what the app displays can't change what the customer is
  /// charged.
  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider.notifier);
    final address = ref.read(selectedAddressProvider);
    final coupon = ref.read(orderSummaryProvider).coupon;
    // Grabbed before the awaits below, so they still work if the screen goes away.
    final couponCtl = ref.read(couponProvider.notifier);
    final pickedAddress = ref.read(selectedAddressIdProvider.notifier);
    final user = ref.read(authControllerProvider).asData?.value;
    final items = ref
        .read(cartProvider)
        .map((i) => OrderItem(
              productSlug: i.product.id,
              name: i.product.name,
              size: i.size,
              qty: i.qty,
              price: i.product.price, // display only; the server re-prices
            ))
        .toList();
    if (items.isEmpty) return;

    final payments = ref.read(paymentRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    // 1 — reserve the order and open a Razorpay order for the real amount.
    _showLoading(context);
    final PaymentSession session;
    try {
      session = await payments.startCheckout(items, couponCode: coupon?.code);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
          content: Text(e.statusCode == 401
              ? 'Please sign in to place an order'
              : e.message)));
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context); // the sheet needs the loader out of the way

    // 2 — hand over to Razorpay.
    final PaymentResult result;
    try {
      // Pre-fill Razorpay so it never asks for what the customer already gave
      // us: the delivery address's phone first, else the one on their account,
      // whichever is a valid number once cleaned up.
      final contact = [address?.phone, user?.phone]
          .map(razorpayContact)
          .whereType<String>()
          .firstOrNull;
      result = await payments.presentCheckout(session,
          contact: contact, email: user?.email);
    } on PaymentCancelled catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    // Money has moved. Clear the cart now so a retry can't charge them twice,
    // whatever verification says next.
    cart.clear();
    couponCtl.remove();
    pickedAddress.clear();

    // 3 — only the backend can validate the signature.
    if (context.mounted) _showLoading(context);
    try {
      final order = await payments.verify(result);
      ref.invalidate(ordersProvider);
      if (!context.mounted) return;
      Navigator.pop(context);
      _confirmation(context, order.reference);
    } on ApiException catch (e) {
      ref.invalidate(ordersProvider);
      if (!context.mounted) return;
      Navigator.pop(context);
      // A 400 means the signature genuinely didn't check out. Anything else
      // (offline, timeout, 5xx) is us failing to confirm a payment that most
      // likely succeeded — the Razorpay webhook settles it either way, so don't
      // tell the customer it failed when they've been charged.
      _confirmation(
        context,
        session.reference,
        problem: e.statusCode == 400
            ? "We couldn't verify this payment. If you were charged, quote this "
                'reference to support and it will be resolved.'
            : "Payment received. We couldn't confirm the order just now — it "
                'will appear in My Orders shortly.',
      );
    }
  }

  void _showLoading(BuildContext context) => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

  /// Success sheet. [problem] is set when the payment went through but we
  /// couldn't confirm the order — the reference is what support needs, so it
  /// stays on screen either way.
  void _confirmation(BuildContext context, String reference, {String? problem}) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(problem == null ? Icons.check_circle_outline : Icons.info_outline,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(problem == null ? 'Order placed!' : 'Payment received',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (problem != null) ...[
              const SizedBox(height: 8),
              Text(problem,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, height: 1.4)),
            ],
            const SizedBox(height: 6),
            Text('Reference #$reference',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'View My Orders',
              onPressed: () {
                Navigator.pop(context);
                context.go('/orders');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceLine(String label, String value,
          {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: bold ? 16 : 14,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: bold ? AppColors.textPrimary : AppColors.textMuted)),
            Text(value,
                style: TextStyle(
                    fontSize: bold ? 16 : 14,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: color ?? AppColors.textPrimary)),
          ],
        ),
      );
}

Widget _card(Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
