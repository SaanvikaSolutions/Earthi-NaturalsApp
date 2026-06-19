import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common_widgets.dart';
import '../cart/cart_controller.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

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
                children: const [
                  Icon(Icons.local_shipping_outlined,
                      color: AppColors.primary),
                  SizedBox(width: 12),
                  Text('Delivery to Keerthi, 500081',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                  'Road no 23, Kakatiya hills, Madhapur, Hyderabad, India, 500081\n+91 8564254656',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.chipBg,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.input)),
                  ),
                  child: const Text('Change or Edit Address'),
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
              _priceLine('Cart total (${items.length} items)', '₹${cart.cartTotal}'),
              _priceLine('Discount on MRP', '-₹${cart.discount}',
                  color: AppColors.discountText),
              _priceLine('Delivery Fee', '₹${cart.deliveryFee}'),
              const Divider(height: 24),
              _priceLine('You Pay', '₹${cart.grandTotal}', bold: true),
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
                          width: 56, height: 56, child: ProductImage()),
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
            onPressed: () => _stubPayment(context),
          ),
        ),
      ),
    );
  }

  void _stubPayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payments_outlined,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text('Payment gateway coming soon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
                'Razorpay (UPI / cards / netbanking) will be wired in here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Got it', onPressed: () => Navigator.pop(context)),
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
