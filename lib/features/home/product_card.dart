import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/wishlist_heart.dart';
import '../../data/models/product.dart';
import '../cart/cart_controller.dart';

/// Product card used in best-sellers / just-dropped grids on Home.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.width = 170});

  final Product product;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The card adds the first/default size; the button reflects that line.
    final defaultSize =
        product.sizes.isNotEmpty ? product.sizes.first : 'Default';
    final cart = ref.watch(cartProvider);
    CartItem? line;
    for (final item in cart) {
      if (item.product.id == product.id && item.size == defaultSize) {
        line = item;
        break;
      }
    }

    return GestureDetector(
      onTap: () => context.push('/product', extra: product),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ProductImage(
                        label: product.name, imageUrl: product.imageUrl),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: WishlistHeartButton(
                        productId: product.id,
                        iconSize: 18,
                        compact: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  RatingRow(
                      rating: product.rating, reviews: product.reviews, size: 11),
                  const SizedBox(height: 6),
                  PriceRow(
                      price: product.price, mrp: product.mrp, priceSize: 14),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: line == null
                        ? _addButton(context, ref, defaultSize)
                        : _qtyControl(ref, line),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "ADD TO CART" — adds the default size, then shows a confirmation.
  Widget _addButton(BuildContext context, WidgetRef ref, String size) =>
      OutlinedButton(
        onPressed: () {
          ref.read(cartProvider.notifier).add(product, size);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              duration: const Duration(milliseconds: 900),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.pill)),
        ),
        child: const Text('ADD TO CART',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      );

  /// Pill "−  qty  +" stepper shown once the item is in the cart. Stepping
  /// below 1 removes the line (button reverts to "ADD TO CART").
  Widget _qtyControl(WidgetRef ref, CartItem line) {
    final cart = ref.read(cartProvider.notifier);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepBtn(Icons.remove, () {
            if (line.qty > 1) {
              cart.setQty(line, line.qty - 1);
            } else {
              cart.remove(line);
            }
          }),
          Text('${line.qty}',
              style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          _stepBtn(Icons.add, () => cart.setQty(line, line.qty + 1)),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Icon(icon, size: 16, color: AppColors.onPrimary),
        ),
      );
}
