import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/product.dart';
import '../home/product_card.dart';

/// Full catalogue with a search field and category filter chips, laid out as
/// a 2-column product grid. Reached from the Collection landing's
/// "Browse All Products" CTA.
class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key, this.initialCategory = 'All'});

  final String initialCategory;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

enum _Sort { popular, priceLowHigh, priceHighLow, rating, discount }

class _AllProductsScreenState extends State<AllProductsScreen> {
  // 'All' shows everything; otherwise filter by Product.category.
  late String _category = widget.initialCategory;
  String _query = '';

  _Sort _sort = _Sort.popular;
  String _priceBand = 'All'; // All / Under ₹500 / ₹500–₹1000 / Above ₹1000
  bool _discountedOnly = false;

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

  bool get _filterActive => _priceBand != 'All' || _discountedOnly;

  List<String> get _filters => ['All', ...MockData.categories];

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

  List<Product> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = MockData.products.where((p) {
      final matchesCat = _category == 'All' || p.category == _category;
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      final matchesDiscount = !_discountedOnly || p.discountPercent > 0;
      return matchesCat && matchesQuery && matchesDiscount && _matchesBand(p);
    }).toList();

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
    final products = _filtered;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _searchField(),
            const SizedBox(height: Gap.md),
            _categoryChips(),
            const SizedBox(height: Gap.md),
            _sortFilterRow(),
            const SizedBox(height: Gap.sm),
            Expanded(
              child: products.isEmpty
                  ? _emptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          Gap.pagePadding, 4, Gap.pagePadding, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => ProductCard(
                          product: products[i], width: double.infinity),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
        padding:
            const EdgeInsets.fromLTRB(Gap.sm, 8, Gap.pagePadding, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            const Text('All Products',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${_filtered.length} items',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _searchField() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search products',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.chipBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.input),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );

  Widget _categoryChips() => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final label = _filters[i];
            final selected = label == _category;
            return GestureDetector(
              onTap: () => setState(() => _category = label),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.chipBg,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? AppColors.onPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _sortFilterRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        child: Row(
          children: [
            Expanded(
              child: _barButton(
                Icons.swap_vert,
                'Sort',
                active: _sort != _Sort.popular,
                onTap: _openSort,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _barButton(
                Icons.tune,
                'Filter',
                active: _filterActive,
                onTap: _openFilter,
              ),
            ),
          ],
        ),
      );

  Widget _barButton(IconData icon, String label,
          {required bool active, required VoidCallback onTap}) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              active ? AppColors.primary : AppColors.textPrimary,
          backgroundColor: active
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          side: BorderSide(
              color: active ? AppColors.primary : AppColors.inputBorder),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.input)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
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
              child: Text('Sort by',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            ..._Sort.values.map((s) => RadioListTile<_Sort>(
                  value: s,
                  groupValue: _sort,
                  activeColor: AppColors.primary,
                  title: Text(_sortLabels[s]!),
                  onChanged: (v) {
                    setState(() => _sort = v!);
                    Navigator.pop(context);
                  },
                )),
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
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(Gap.pagePadding, 16, Gap.pagePadding, 4),
                child: Row(
                  children: [
                    const Text('Filter',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _priceBand = 'All';
                          _discountedOnly = false;
                        });
                        setSheet(() {});
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(Gap.pagePadding, 4, 0, 4),
                child: Text('Price',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              ..._priceBands.map((band) => RadioListTile<String>(
                    value: band,
                    groupValue: _priceBand,
                    activeColor: AppColors.primary,
                    dense: true,
                    title: Text(band),
                    onChanged: (v) {
                      setState(() => _priceBand = v!);
                      setSheet(() {});
                    },
                  )),
              SwitchListTile(
                value: _discountedOnly,
                activeThumbColor: AppColors.primary,
                title: const Text('Discounted only'),
                onChanged: (v) {
                  setState(() => _discountedOnly = v);
                  setSheet(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.all(Gap.pagePadding),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.pill)),
                    ),
                    child: Text('Show ${_filtered.length} results',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No products found',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
}
