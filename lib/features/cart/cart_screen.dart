import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/product.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text('Cart (${items.length.toString().padLeft(2, '0')})',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('Your cart is empty',
                  style: TextStyle(color: AppColors.textMuted)))
          : ListView(
              padding: const EdgeInsets.all(Gap.pagePadding),
              children: [
                _addressCard(),
                const SizedBox(height: 14),
                _card(Column(
                  children: [
                    for (final item in items) ...[
                      _CartItemRow(
                        item: item,
                        onQty: (q) => cart.setQty(item, q),
                        onRemove: () => _confirmRemove(context, cart, item),
                      ),
                      if (item != items.last)
                        const Divider(height: 24),
                    ],
                    const SizedBox(height: 12),
                    SecondaryButton(label: 'Add More Items', onPressed: () => context.go('/home')),
                  ],
                )),
                const SizedBox(height: 14),
                _couponCard(),
              ],
            ),
      bottomNavigationBar: items.isEmpty ? null : _payBar(context, cart),
    );
  }

  Widget _addressCard() => _card(Row(
        children: [
          const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery to Keerthi, 500081',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Road no 23, Kakatiya hills, Madha...',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.pill)),
            ),
            child: const Text('Change'),
          ),
        ],
      ));

  Widget _couponCard() => _card(Row(
        children: [
          const Icon(Icons.local_offer_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Add Coupon code',
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.chipBg,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.input),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PrimaryButton(
            label: 'Apply',
            color: AppColors.accentBlack,
            height: 44,
            onPressed: () {},
          ).constrainWidth(96),
        ],
      ));

  Widget _payBar(BuildContext context, CartController cart) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(Gap.pagePadding, 10, Gap.pagePadding, 10),
          color: AppColors.surface,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹${cart.grandTotal}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const Text('Grand Total',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  label: 'Proceed to Pay',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.push('/checkout'),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _confirmRemove(
      BuildContext context, CartController cart, CartItem item) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                      width: 56, height: 56, child: ProductImage()),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(item.product.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Remove',
                      onPressed: () {
                        cart.remove(item);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Move to wishlist',
                      height: 52,
                      onPressed: () {
                        cart.remove(item);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _CartItemRow extends StatelessWidget {
  const _CartItemRow(
      {required this.item, required this.onQty, required this.onRemove});

  final CartItem item;
  final ValueChanged<int> onQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 72, height: 72, child: ProductImage()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.remove),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(item.size,
                            style: const TextStyle(fontSize: 12)),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                  const Spacer(),
                  QtyStepper(value: item.qty, onChanged: onQty),
                ],
              ),
              const SizedBox(height: 8),
              PriceRow(
                  price: item.product.price,
                  mrp: item.product.mrp,
                  priceSize: 14),
              const SizedBox(height: 4),
              const Text('Delivery by Wed, 12 Jul',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

extension on Widget {
  Widget constrainWidth(double w) => SizedBox(width: w, child: this);
}
