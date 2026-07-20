import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../home/product_card.dart';
import 'product_sort_filter.dart';

/// Category listing — opened from a Home category tile. Loads products for the
/// category from the backend and lets the user narrow by subcategory.
/// A null [category] means "Collection" (all products).
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, this.category});

  final Category? category;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  /// Selected subcategory id, or null for "All".
  String? _subcategoryId;
  ProductSort _sort = ProductSort.popular;
  String _priceBand = 'All';
  bool _discountedOnly = false;

  Category? get _category => widget.category;
  bool get _isCollection => _category == null;

  List<Product> _apply(List<Product> list) => applyProductSortFilter(
        list,
        sort: _sort,
        priceBand: _priceBand,
        discountedOnly: _discountedOnly,
      );

  @override
  Widget build(BuildContext context) {
    final filter = (
      categoryId: _category?.id,
      subcategoryId: _subcategoryId,
    );
    final products = ref.watch(productsByCategoryProvider(filter));
    final subs = _category?.subcategories ?? const <Subcategory>[];
    final dataList = products.asData?.value ?? const <Product>[];

    return Scaffold(
      bottomNavigationBar: SortFilterBar(
        sortActive: _sort != ProductSort.popular,
        filterActive: _priceBand != 'All' || _discountedOnly,
        onSort: () async {
          final s = await openSortSheet(context, _sort);
          if (s != null) setState(() => _sort = s);
        },
        onFilter: () async {
          final r = await openFilterSheet(
            context,
            priceBand: _priceBand,
            discountedOnly: _discountedOnly,
            resultCount: (band, disc) => applyProductSortFilter(
              dataList,
              sort: _sort,
              priceBand: band,
              discountedOnly: disc,
            ).length,
          );
          if (r != null) {
            setState(() {
              _priceBand = r.priceBand;
              _discountedOnly = r.discountedOnly;
            });
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Gap.pagePadding, 4, Gap.pagePadding, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isCollection ? 'Collection' : _category!.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      products.maybeWhen(
                        data: (list) {
                          final n = _apply(list).length;
                          return '$n ${n == 1 ? 'Product' : 'Products'}';
                        },
                        orElse: () => '…',
                      ),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (subs.isNotEmpty) _subcategoryChips(subs),
            const SizedBox(height: 8),
            Expanded(
              child: products.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _errorState(filter),
                data: (list) {
                  final filtered = _apply(list);
                  if (filtered.isEmpty) return _emptyState();
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        Gap.pagePadding, 4, Gap.pagePadding, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => ProductCard(
                        product: filtered[i], width: double.infinity),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal "All / <subcategory>" chips for this category.
  Widget _subcategoryChips(List<Subcategory> subs) {
    final items = <Subcategory?>[null, ...subs]; // null == "All"
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sub = items[i];
          final selected = sub?.id == _subcategoryId;
          return ChoiceChip(
            label: Text(sub?.name ?? 'All'),
            selected: selected,
            onSelected: (_) => setState(() => _subcategoryId = sub?.id),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.chipBg,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.pill),
              side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.inputBorder),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No products here yet',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _errorState(ProductFilter filter) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text("Couldn't load products",
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () =>
                    ref.invalidate(productsByCategoryProvider(filter)),
                child: const Text('Retry')),
          ],
        ),
      );

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
                onPressed: () => context.push('/all-products'),
                icon: const Icon(Icons.search)),
            WishlistIconButton(
                onPressed: () => context.push('/wishlist')),
            CartIconButton(
                onPressed: () => context.go('/cart')),
          ],
        ),
      );
}
