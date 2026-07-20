import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/count_badge.dart';
import '../../core/widgets/wishlist_heart.dart';
import '../../data/models/product.dart';
import '../cart/cart_controller.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  late String _size = widget.product.sizes.first;
  int _qty = 1;

  static const _trust = [
    ('Made with 100%\nNatural Ingredients', Icons.eco_outlined),
    ('Dermatologically\nTested & Certified', Icons.verified_outlined),
    ('Fast & Eco-\nFriendly Delivery', Icons.local_shipping_outlined),
    ('Gentle Yet\nEffective Formulas', Icons.spa_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(
            onPressed: () => context.push('/all-products'),
            icon: const Icon(Icons.search),
          ),
          WishlistHeartButton(productId: p.id, iconSize: 24),
          CartIconButton(
            onPressed: () => context.push('/cart'),
            icon: Icons.shopping_bag_outlined,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ProductImage(
              radius: 16,
              label: p.name,
              imageUrl: p.imageUrl,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          RatingRow(rating: p.rating, reviews: p.reviews),
          const SizedBox(height: 10),
          PriceRow(price: p.price * _qty, mrp: p.mrp * _qty, priceSize: 22),
          const SizedBox(height: 14),
          Text(
            p.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sizes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: p.sizes.map((s) {
              final selected = s == _size;
              return ChoiceChip(
                label: Text(s),
                selected: selected,
                onSelected: (_) => setState(() => _size = s),
                // Without this the chip grows by the checkmark's width when
                // selected, which reflows the Wrap and makes the row jump.
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.chipBg,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  side: const BorderSide(color: AppColors.inputBorder),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Quantity',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              QtyStepper(
                value: _qty,
                onChanged: (v) => setState(() => _qty = v),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _trustGrid(),
          const SizedBox(height: 22),
          _expandable('Product Details', p.description),
          _expandable(
            'Ingredients',
            'Aloe vera, neem, turmeric, vitamin E, and a blend of cold-pressed herbal oils.',
          ),
          _expandable(
            'How to Use',
            'Take a few drops in your palm, apply evenly, and gently massage. Use daily for best results.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Ratings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _ratingsSummary(p),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _bottomBar(context, p),
    );
  }

  Widget _trustGrid() => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 3.4,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    children: _trust
        .map(
          (t) => Row(
            children: [
              Icon(t.$2, color: AppColors.primary, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.$1,
                  style: const TextStyle(fontSize: 11, height: 1.2),
                ),
              ),
            ],
          ),
        )
        .toList(),
  );

  Widget _expandable(String title, String body) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _ratingsSummary(Product p) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Text(
            p.rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
          ),
          Text(
            '${p.reviews} reviews',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(
          children: List.generate(5, (i) {
            final star = 5 - i;
            final frac = [0.9, 0.6, 0.25, 0.1, 0.02][i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('$star', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    ],
  );

  Widget _bottomBar(BuildContext context, Product p) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        Gap.pagePadding,
        8,
        Gap.pagePadding,
        8,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Buy Now',
              color: AppColors.accentBlack,
              onPressed: () {
                ref.read(cartProvider.notifier).add(p, _size, qty: _qty);
                context.push('/checkout');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Add To Cart',
              onPressed: () {
                ref.read(cartProvider.notifier).add(p, _size, qty: _qty);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to cart'),
                    duration: Duration(milliseconds: 900),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
