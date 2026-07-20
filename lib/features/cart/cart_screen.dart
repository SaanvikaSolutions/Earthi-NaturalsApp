import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/api/api_client.dart';
import '../../data/models/product.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../profile/address_controller.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    return PopScope(
      // When the cart is opened from the bottom-nav tab (via `go`) there's
      // nothing to pop, so a system back would exit the app — send it Home.
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F7F5),
          leading: BackButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          title: Text(
            'Cart (${items.length.toString().padLeft(2, '0')})',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            WishlistIconButton(onPressed: () => context.push('/wishlist')),
          ],
        ),
        body: items.isEmpty
            ? const Center(
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(Gap.pagePadding),
                children: [
                  _addressCard(context, ref.watch(selectedAddressProvider)),
                  const SizedBox(height: 14),
                  _card(
                    Column(
                      children: [
                        for (final item in items) ...[
                          _CartItemRow(
                            item: item,
                            onQty: (q) => cart.setQty(item, q),
                            onSize: (s) => cart.setSize(item, s),
                            onRemove: () =>
                                _confirmRemove(context, ref, cart, item),
                          ),
                          if (item != items.last) const Divider(height: 24),
                        ],
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: 'Add More Items',
                          onPressed: () => context.push('/all-products'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _couponCard(),
                ],
              ),
        bottomNavigationBar: items.isEmpty ? null : _payBar(context, cart),
      ),
    );
  }

  Widget _addressCard(BuildContext context, Address? address) => _card(
    Row(
      children: [
        const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address == null
                    ? 'No delivery address'
                    : 'Delivery to ${address.name}'
                        '${address.pincode.isEmpty ? '' : ', ${address.pincode}'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                address?.line ?? 'Add one to continue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => context.push('/addresses'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.inputBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
          child: const Text('Change'),
        ),
      ],
    ),
  );

  Widget _couponCard() => _card(
    Row(
      children: [
        const Icon(Icons.local_offer_outlined, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Add Coupon code',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.chipBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.input),
                borderSide: BorderSide.none,
              ),
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
    ),
  );

  Widget _payBar(BuildContext context, CartController cart) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        Gap.pagePadding,
        10,
        Gap.pagePadding,
        10,
      ),
      color: AppColors.surface,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹${cart.grandTotal}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
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
    BuildContext context,
    WidgetRef ref,
    CartController cart,
    CartItem item,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ProductImage(imageUrl: item.product.imageUrl),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Move to wishlist',
                      height: 52,
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _moveToWishlist(context, ref, cart, item);
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

  /// Adds the product to the wishlist (backend), then removes it from the cart.
  Future<void> _moveToWishlist(
    BuildContext context,
    WidgetRef ref,
    CartController cart,
    CartItem item,
  ) async {
    try {
      await ref.read(wishlistRepositoryProvider).add(item.product.id);
      ref.invalidate(wishlistProvider);
      cart.remove(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.product.name} moved to wishlist'),
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } on ApiException catch (e) {
      // If the user isn't signed in, still remove from cart but tell them.
      cart.remove(item);
      if (context.mounted) {
        final msg = e.statusCode == 401
            ? 'Sign in to save items to your wishlist'
            : e.message;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
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
  const _CartItemRow({
    required this.item,
    required this.onQty,
    required this.onSize,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQty;
  final ValueChanged<String> onSize;
  final VoidCallback onRemove;

  /// The size pill doubles as a picker over this product's other sizes, so a
  /// user can switch size without leaving the cart.
  Widget _sizeSelector() {
    final sizes = item.product.sizes;
    final enabled = sizes.length > 1;
    return PopupMenuButton<String>(
      enabled: enabled,
      initialValue: item.size,
      tooltip: enabled ? 'Change size' : 'Only one size available',
      position: PopupMenuPosition.under,
      onSelected: onSize,
      itemBuilder: (_) => [
        for (final s in sizes)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Text(s),
                if (s == item.size) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.size, style: const TextStyle(fontSize: 12)),
            if (enabled) const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push('/product', extra: item.product),
          child: SizedBox(
            width: 72,
            height: 72,
            child: ProductImage(imageUrl: item.product.imageUrl),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/product', extra: item.product),
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.remove,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _sizeSelector(),
                  const Spacer(),
                  QtyStepper(value: item.qty, onChanged: onQty),
                ],
              ),
              const SizedBox(height: 8),
              PriceRow(
                price: item.product.price * item.qty,
                mrp: item.product.mrp * item.qty,
                priceSize: 14,
              ),
              const SizedBox(height: 4),
              const Text(
                'Delivery by Wed, 12 Jul',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
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
