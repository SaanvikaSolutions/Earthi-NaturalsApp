import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../theme/app_colors.dart';

/// Heart toggle that saves/removes a product from the signed-in user's
/// wishlist. Shared by the product detail page and the product cards so the
/// filled/outlined state stays in sync everywhere the product appears.
class WishlistHeartButton extends ConsumerStatefulWidget {
  const WishlistHeartButton({
    super.key,
    required this.productId,
    this.iconSize = 20,
    this.compact = false,
  });

  final String productId;

  final double iconSize;

  /// Tightens the tap padding for use on a product card, where the button sits
  /// over the image rather than in an app bar.
  final bool compact;

  @override
  ConsumerState<WishlistHeartButton> createState() =>
      _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends ConsumerState<WishlistHeartButton> {
  bool _busy = false;

  Future<void> _toggle(bool currentlySaved) async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(wishlistRepositoryProvider);
    try {
      if (currentlySaved) {
        await repo.remove(widget.productId);
      } else {
        await repo.add(widget.productId);
      }
      ref.invalidate(wishlistProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(currentlySaved ? 'Removed from wishlist' : 'Added to wishlist'),
        duration: const Duration(milliseconds: 900),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.statusCode == 401
          ? 'Please sign in to use your wishlist'
          : e.message;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(wishlistProvider).maybeWhen(
          data: (items) => items.any((p) => p.id == widget.productId),
          orElse: () => false,
        );
    return IconButton(
      tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
      onPressed: _busy ? null : () => _toggle(saved),
      visualDensity: widget.compact ? VisualDensity.compact : null,
      padding: widget.compact ? const EdgeInsets.all(6) : null,
      constraints: widget.compact ? const BoxConstraints() : null,
      icon: Icon(
        saved ? Icons.favorite : Icons.favorite_border,
        size: widget.iconSize,
        color: saved ? AppColors.remove : AppColors.textPrimary,
      ),
    );
  }
}
