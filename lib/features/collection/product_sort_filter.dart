import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';

/// Shared sort/filter logic + UI used by the category and All-Products screens.

enum ProductSort { popular, priceLowHigh, priceHighLow, rating, discount }

const Map<ProductSort, String> kSortLabels = {
  ProductSort.popular: 'Popularity',
  ProductSort.priceLowHigh: 'Price: Low to High',
  ProductSort.priceHighLow: 'Price: High to Low',
  ProductSort.rating: 'Customer rating',
  ProductSort.discount: 'Discount',
};

const List<String> kPriceBands = [
  'All',
  'Under ₹500',
  '₹500 – ₹1000',
  'Above ₹1000',
];

bool _matchesBand(Product p, String band) {
  switch (band) {
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

/// Applies price/discount filtering, optional name search, and sorting.
List<Product> applyProductSortFilter(
  List<Product> source, {
  required ProductSort sort,
  required String priceBand,
  required bool discountedOnly,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  final list = source.where((p) {
    final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q);
    final matchesDiscount = !discountedOnly || p.discountPercent > 0;
    return matchesQuery && matchesDiscount && _matchesBand(p, priceBand);
  }).toList();

  switch (sort) {
    case ProductSort.priceLowHigh:
      list.sort((a, b) => a.price.compareTo(b.price));
      break;
    case ProductSort.priceHighLow:
      list.sort((a, b) => b.price.compareTo(a.price));
      break;
    case ProductSort.rating:
      list.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case ProductSort.discount:
      list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      break;
    case ProductSort.popular:
      break;
  }
  return list;
}

/// Result returned by [openFilterSheet].
class FilterResult {
  final String priceBand;
  final bool discountedOnly;
  const FilterResult(this.priceBand, this.discountedOnly);
}

/// Bottom-fixed Sort / Filter bar (place in Scaffold.bottomNavigationBar).
class SortFilterBar extends StatelessWidget {
  const SortFilterBar({
    super.key,
    required this.sortActive,
    required this.filterActive,
    required this.onSort,
    required this.onFilter,
  });

  final bool sortActive;
  final bool filterActive;
  final VoidCallback onSort;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            Gap.pagePadding, 10, Gap.pagePadding, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
                child: _barButton(
                    Icons.swap_vert, 'Sort', active: sortActive, onTap: onSort)),
            const SizedBox(width: 12),
            Expanded(
                child: _barButton(Icons.tune, 'Filter',
                    active: filterActive, onTap: onFilter)),
          ],
        ),
      ),
    );
  }

  Widget _barButton(IconData icon, String label,
          {required bool active, required VoidCallback onTap}) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: active ? AppColors.primary : AppColors.textPrimary,
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
}

/// Opens the Sort bottom sheet, returning the chosen sort (or null if dismissed).
Future<ProductSort?> openSortSheet(BuildContext context, ProductSort current) {
  return showModalBottomSheet<ProductSort>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(Gap.pagePadding, 16, 0, 8),
            child: Text('Sort by',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          ...ProductSort.values.map((s) => RadioListTile<ProductSort>(
                value: s,
                groupValue: current,
                activeColor: AppColors.primary,
                title: Text(kSortLabels[s]!),
                onChanged: (v) => Navigator.pop(ctx, v),
              )),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Opens the Filter bottom sheet. [resultCount] returns how many products
/// match a candidate (priceBand, discountedOnly) for the live button label.
Future<FilterResult?> openFilterSheet(
  BuildContext context, {
  required String priceBand,
  required bool discountedOnly,
  required int Function(String band, bool discounted) resultCount,
}) {
  String band = priceBand;
  bool discounted = discountedOnly;
  return showModalBottomSheet<FilterResult>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Gap.pagePadding, 16, Gap.pagePadding, 4),
              child: Row(
                children: [
                  const Text('Filter',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setSheet(() {
                      band = 'All';
                      discounted = false;
                    }),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(Gap.pagePadding, 4, 0, 4),
              child: Text('Price',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            ...kPriceBands.map((b) => RadioListTile<String>(
                  value: b,
                  groupValue: band,
                  activeColor: AppColors.primary,
                  dense: true,
                  title: Text(b),
                  onChanged: (v) => setSheet(() => band = v!),
                )),
            SwitchListTile(
              value: discounted,
              activeThumbColor: AppColors.primary,
              title: const Text('Discounted only'),
              onChanged: (v) => setSheet(() => discounted = v),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.pagePadding),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(ctx, FilterResult(band, discounted)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.pill)),
                  ),
                  child: Text('Show ${resultCount(band, discounted)} results',
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
