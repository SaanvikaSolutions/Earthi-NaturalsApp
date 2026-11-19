import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/api/api_client.dart';
import '../../data/models/coupon.dart';
import '../../data/models/product.dart';
import '../../data/repositories/coupon_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../profile/address_controller.dart';
import 'cart_controller.dart';
import 'coupon_controller.dart';

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
                  const _CouponCard(),
                ],
              ),
        bottomNavigationBar:
            items.isEmpty ? null : _payBar(context, ref.watch(orderSummaryProvider)),
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

  Widget _payBar(BuildContext context, OrderSummary summary) => SafeArea(
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
                '₹${summary.grandTotal}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                summary.couponDiscount > 0
                    ? 'Grand Total · coupon saves ₹${summary.couponDiscount}'
                    : 'Grand Total',
                style: TextStyle(
                  fontSize: 12,
                  color: summary.couponDiscount > 0
                      ? AppColors.discountText
                      : AppColors.textMuted,
                ),
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

/// Coupon box in the cart: type a code or pick an offer, see the saving, remove it.
class _CouponCard extends ConsumerStatefulWidget {
  const _CouponCard();

  @override
  ConsumerState<_CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends ConsumerState<_CouponCard> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Asks the server whether [picked] (or the typed code) works for this cart.
  Future<void> _apply([String? picked]) async {
    final code = (picked ?? _controller.text).trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a coupon code');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final coupon = await ref
          .read(couponRepositoryProvider)
          .validate(code, ref.read(cartProvider));
      if (!mounted) return;
      ref.read(couponProvider.notifier).apply(coupon);
      _controller.clear();
      setState(() => _busy = false);
      final saved = ref.read(orderSummaryProvider).couponDiscount;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${coupon.code} applied — you save ₹$saved'),
        duration: const Duration(milliseconds: 1500),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message; // "Invalid coupon code", "Add ₹X more...", etc.
      });
    }
  }

  Future<void> _pickOffer() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _OffersSheet(),
    );
    if (code == null || !mounted) return;
    _controller.text = code;
    await _apply(code);
  }

  @override
  Widget build(BuildContext context) {
    final applied = ref.watch(couponProvider);
    final summary = ref.watch(orderSummaryProvider);

    if (applied != null) {
      final problem = summary.couponProblem;
      return _card(
        Row(
          children: [
            Icon(problem == null ? Icons.check_circle : Icons.info_outline,
                size: 22,
                color: problem == null
                    ? AppColors.discountText
                    : AppColors.remove),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    problem == null ? '${applied.code} applied' : applied.code,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    problem ?? 'You save ₹${summary.couponDiscount}',
                    style: TextStyle(
                      fontSize: 12,
                      color: problem == null
                          ? AppColors.discountText
                          : AppColors.remove,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => ref.read(couponProvider.notifier).remove(),
              style: TextButton.styleFrom(foregroundColor: AppColors.remove),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.local_offer_outlined, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _apply(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Add Coupon code',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    errorText: _error,
                    errorMaxLines: 2,
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
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: PrimaryButton(
                  label: _busy ? 'Applying…' : 'Apply',
                  color: AppColors.accentBlack,
                  height: 44,
                  onPressed: _busy ? null : _apply,
                ).constrainWidth(96),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 4),
            child: TextButton(
              onPressed: _busy ? null : _pickOffer,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('View available offers',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet listing the offers; pops the chosen code.
class _OffersSheet extends ConsumerWidget {
  const _OffersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(availableCouponsProvider);
    final cartTotal = ref.watch(orderSummaryProvider).cartTotal;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available offers',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            offers.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  e is ApiException
                      ? e.message
                      : "Couldn't load offers. Try again.",
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No offers right now.',
                          style: TextStyle(color: AppColors.textMuted)),
                    )
                  : Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) =>
                            _offerTile(context, list[i], cartTotal),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerTile(BuildContext context, Coupon c, int cartTotal) {
    final eligible = c.isEligible(cartTotal);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(c.code,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text(
        eligible
            ? '${c.title} · min cart ₹${c.minCart}'
            : '${c.title} · add ₹${c.shortfall(cartTotal)} more to use',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: TextButton(
        onPressed: eligible ? () => Navigator.pop(context, c.code) : null,
        child: const Text('Apply'),
      ),
    );
  }
}
