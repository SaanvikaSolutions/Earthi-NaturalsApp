import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../features/cart/cart_controller.dart';

/// Wraps [child] with a Material badge showing [count] (hidden when 0).
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: child,
    );
  }
}

/// An [IconButton] that navigates to the cart and shows a live badge with the
/// total number of items currently in the cart.
class CartIconButton extends ConsumerWidget {
  const CartIconButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.shopping_cart_outlined,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: CountBadge(count: count, child: Icon(icon)),
    );
  }
}

/// An [IconButton] that navigates to the wishlist and shows a live badge with
/// the number of saved products.
class WishlistIconButton extends ConsumerWidget {
  const WishlistIconButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.favorite_border,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(wishlistCountProvider);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: CountBadge(count: count, child: Icon(icon)),
    );
  }
}
