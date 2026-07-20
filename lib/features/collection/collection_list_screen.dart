import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/product.dart';
import '../cart/cart_controller.dart';

/// The four "Our Collections" cards each open this listing, configured by
/// [CollectionKind] — a title, an image badge, and the product set/sort.
enum CollectionKind { newArrival, bestseller, topRated, discount }

class _Config {
  final String title;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  const _Config(this.title, this.badge, this.badgeBg, this.badgeFg);
}

const _configs = {
  CollectionKind.newArrival: _Config(
    'Just Dropped',
    'New',
    Color(0xFFE6F0DD),
    AppColors.primary,
  ),
  CollectionKind.bestseller: _Config(
    'Bestsellers',
    'Bestseller',
    AppColors.accentBlack,
    Colors.white,
  ),
  CollectionKind.topRated: _Config(
    'Top Rated',
    'Top Rated',
    AppColors.accentBlack,
    Colors.white,
  ),
  CollectionKind.discount: _Config(
    'Discount',
    'Sale',
    AppColors.accentBlack,
    Colors.white,
  ),
};

enum _Sort { popular, priceLowHigh, priceHighLow, rating, discount }

class CollectionListScreen extends StatefulWidget {
  const CollectionListScreen({super.key, required this.kind});

  final CollectionKind kind;

  @override
  State<CollectionListScreen> createState() => _CollectionListScreenState();
}

class _CollectionListScreenState extends State<CollectionListScreen> {
  static const _sortLabels = {
    _Sort.popular: 'Popularity',
    _Sort.priceLowHigh: 'Price: Low to High',
    _Sort.priceHighLow: 'Price: High to Low',
    _Sort.rating: 'Customer rating',
    _Sort.discount: 'Discount',
  };
  static const _priceBands = [
    'All',
    'Under ₹500',
    '₹500 – ₹1000',
    'Above ₹1000',
  ];

  _Sort _sort = _Sort.popular;
  String _priceBand = 'All';

  _Config get _cfg => _configs[widget.kind]!;

  bool _matchesBand(Product p) {
    switch (_priceBand) {
      case 'Under ₹500':
        return p.price < 500;
      case '₹500 – ₹1000':
        return p.price >= 500 && p.price <= 1000;
      case 'Above ₹1000':
        return p.price > 1000;
      default:
        return true;
    }
  }

  List<Product> get _products {
    var list = MockData.products.where(_matchesBand).toList();
    // Base ordering per collection.
    switch (widget.kind) {
      case CollectionKind.newArrival:
        list = list.reversed.toList();
        break;
      case CollectionKind.bestseller:
        list.sort((a, b) => b.reviews.compareTo(a.reviews));
        break;
      case CollectionKind.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case CollectionKind.discount:
        list = list.where((p) => p.discountPercent > 0).toList();
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
    }
    // User-chosen sort overrides.
    switch (_sort) {
      case _Sort.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _Sort.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _Sort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _Sort.discount:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case _Sort.popular:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    return Scaffold(
      bottomNavigationBar: SafeArea(top: false, child: _bottomBar()),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(products.length)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.pagePadding,
                      4,
                      Gap.pagePadding,
                      24,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.54,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _CollectionCard(
                          product: products[i],
                          badge: _cfg.badge,
                          badgeBg: _cfg.badgeBg,
                          badgeFg: _cfg.badgeFg,
                        ),
                        childCount: products.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
    child: Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const BrandLogo(width: 110),
        const Spacer(),
        IconButton(
          onPressed: () => context.push('/all-products'),
          icon: const Icon(Icons.search),
        ),
        WishlistIconButton(onPressed: () => context.push('/wishlist')),
        CartIconButton(onPressed: () => context.push('/cart')),
      ],
    ),
  );

  Widget _header(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.pagePadding, 4, Gap.pagePadding, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _cfg.title,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count Products',
          style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
      ],
    ),
  );

  Widget _bottomBar() => Container(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    padding: const EdgeInsets.fromLTRB(
      Gap.pagePadding,
      10,
      Gap.pagePadding,
      10,
    ),
    child: Row(
      children: [
        Expanded(
          child: _barButton(
            Icons.swap_vert,
            'Sort by',
            active: _sort != _Sort.popular,
            onTap: _openSort,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _barButton(
            Icons.tune,
            'Filter',
            active: _priceBand != 'All',
            onTap: _openFilter,
          ),
        ),
      ],
    ),
  );

  Widget _barButton(
    IconData icon,
    String label, {
    required bool active,
    required VoidCallback onTap,
  }) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: active ? AppColors.primary : AppColors.textPrimary,
      backgroundColor: active
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      side: BorderSide(
        color: active ? AppColors.primary : AppColors.inputBorder,
      ),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.input),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  void _openSort() {
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
            const Padding(
              padding: EdgeInsets.fromLTRB(Gap.pagePadding, 16, 0, 8),
              child: Text(
                'Sort by',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            ..._Sort.values.map(
              (s) => RadioListTile<_Sort>(
                value: s,
                groupValue: _sort,
                activeColor: AppColors.primary,
                title: Text(_sortLabels[s]!),
                onChanged: (v) {
                  setState(() => _sort = v!);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(Gap.pagePadding, 16, 0, 4),
                child: Text(
                  'Filter by price',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              ..._priceBands.map(
                (band) => RadioListTile<String>(
                  value: band,
                  groupValue: _priceBand,
                  activeColor: AppColors.primary,
                  dense: true,
                  title: Text(band),
                  onChanged: (v) {
                    setState(() => _priceBand = v!);
                    setSheet(() {});
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rich product card: badged image, 5-star rating, price, add-to-cart + heart.
class _CollectionCard extends ConsumerStatefulWidget {
  const _CollectionCard({
    required this.product,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
  });

  final Product product;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;

  @override
  ConsumerState<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends ConsumerState<_CollectionCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTap: () => context.push('/product', extra: p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(label: p.name, imageUrl: p.imageUrl),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.badgeBg,
                      borderRadius: BorderRadius.circular(Radii.badge),
                    ),
                    child: Text(
                      widget.badge,
                      style: TextStyle(
                        color: widget.badgeFg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          _stars(p.rating, p.reviews),
          const SizedBox(height: 6),
          PriceRow(price: p.price, mrp: p.mrp, priceSize: 17),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).add(p, p.sizes.first);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${p.name} added to cart'),
                          duration: const Duration(milliseconds: 900),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                    ),
                    child: const Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _liked = !_liked),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: _liked ? AppColors.remove : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stars(double rating, int reviews) {
    final full = rating.round().clamp(0, 5);
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full ? Icons.star : Icons.star_border,
            size: 16,
            color: AppColors.star,
          ),
        const SizedBox(width: 6),
        Text(
          '$reviews reviews',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
