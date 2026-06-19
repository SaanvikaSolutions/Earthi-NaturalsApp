import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/product.dart';
import '../home/product_card.dart';

/// Category listing — opened from a Home category tile. Shows the category
/// title, product count, a 2-column grid and a Sort / Filter bar.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  /// Display name, e.g. 'Skin care'. 'Collection' (or unknown) shows all.
  final String category;

  List<Product> get _products {
    final matches = MockData.products
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
    // Fall back to the full catalogue for categories without mock items
    // (so Body / Baby tiles still show a populated grid).
    return matches.isEmpty ? MockData.products : matches;
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    // Plausible mock count so the header reads like the real catalogue.
    final count = 2400 + category.length * 31;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Gap.pagePadding, 4, Gap.pagePadding, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('$count  Products',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                    Gap.pagePadding, 4, Gap.pagePadding, 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) =>
                    ProductCard(product: products[i], width: double.infinity),
              ),
            ),
            _sortFilterBar(context),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back)),
            const BrandLogo(width: 110),
            const Spacer(),
            IconButton(
                onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(
                onPressed: () => context.push('/wishlist'),
                icon: const Icon(Icons.favorite_border)),
            IconButton(
                onPressed: () => context.go('/cart'),
                icon: const Icon(Icons.shopping_cart_outlined)),
          ],
        ),
      );

  Widget _sortFilterBar(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(
            Gap.pagePadding, 10, Gap.pagePadding, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(child: _barButton(context, Icons.swap_vert, 'Sort by')),
            const SizedBox(width: 14),
            Expanded(child: _barButton(context, Icons.tune, 'Filter')),
          ],
        ),
      );

  Widget _barButton(BuildContext context, IconData icon, String label) =>
      OutlinedButton(
        onPressed: () => _showSheet(context, label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.inputBorder),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.input)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  void _showSheet(BuildContext context, String which) {
    final options = which == 'Sort by'
        ? const [
            'Popularity',
            'Price: Low to High',
            'Price: High to Low',
            'Newest first',
            'Customer rating',
          ]
        : const [
            'Skin care',
            'Hair care',
            'Body Care',
            'Baby Care',
            'Under ₹500',
            'Discounted',
          ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.pagePadding, 16, 0, 8),
              child: Text(which,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            ...options.map((o) => ListTile(
                  title: Text(o),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
                  onTap: () => Navigator.pop(context),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
