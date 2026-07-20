import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../data/repositories/product_repository.dart';
import '../home/product_card.dart';
import 'product_sort_filter.dart';

/// Full catalogue (loaded from the API) with a search field, real category
/// filter chips, and a bottom-fixed Sort / Filter bar.
class AllProductsScreen extends ConsumerStatefulWidget {
  const AllProductsScreen({super.key, this.initialCategory = 'All'});

  /// Category name to preselect (e.g. 'Skin'); 'All' shows everything.
  final String initialCategory;

  @override
  ConsumerState<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends ConsumerState<AllProductsScreen> {
  late String _categoryName = widget.initialCategory;
  String _query = '';
  ProductSort _sort = ProductSort.popular;
  String _priceBand = 'All';
  bool _discountedOnly = false;

  /// Products in the selected category (before price/discount/sort).
  List<Product> _byCategory(List<Product> all, List<Category> categories) {
    if (_categoryName == 'All') return all;
    final match = categories
        .where((c) => c.name.toLowerCase() == _categoryName.toLowerCase());
    if (match.isEmpty) return all;
    final id = match.first.id;
    return all.where((p) => p.category == id).toList();
  }

  List<Product> _apply(List<Product> all, List<Category> categories) =>
      applyProductSortFilter(
        _byCategory(all, categories),
        sort: _sort,
        priceBand: _priceBand,
        discountedOnly: _discountedOnly,
        query: _query,
      );

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(productCatalogProvider);
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <Category>[];
    final filters = <String>['All', ...categories.map((c) => c.name)];

    return Scaffold(
      bottomNavigationBar: SortFilterBar(
        sortActive: _sort != ProductSort.popular,
        filterActive: _priceBand != 'All' || _discountedOnly,
        onSort: () async {
          final s = await openSortSheet(context, _sort);
          if (s != null) setState(() => _sort = s);
        },
        onFilter: () async {
          final all = catalog.asData?.value ?? const <Product>[];
          final r = await openFilterSheet(
            context,
            priceBand: _priceBand,
            discountedOnly: _discountedOnly,
            resultCount: (band, disc) => applyProductSortFilter(
              _byCategory(all, categories),
              sort: _sort,
              priceBand: band,
              discountedOnly: disc,
              query: _query,
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
          children: [
            _topBar(catalog.asData?.value, categories),
            _searchField(),
            const SizedBox(height: Gap.md),
            if (filters.length > 1) _categoryChips(filters),
            const SizedBox(height: Gap.sm),
            Expanded(
              child: catalog.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _errorState(),
                data: (all) {
                  final products = _apply(all, categories);
                  if (products.isEmpty) return _emptyState();
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
                    itemCount: products.length,
                    itemBuilder: (_, i) => ProductCard(
                        product: products[i], width: double.infinity),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(List<Product>? all, List<Category> categories) {
    final count = all == null ? null : _apply(all, categories).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.sm, 8, Gap.pagePadding, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const Text('All Products',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (count != null)
            Text('$count items',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

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

  Widget _categoryChips(List<String> filters) => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final label = filters[i];
            final selected = label == _categoryName;
            return GestureDetector(
              onTap: () => setState(() => _categoryName = label),
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

  Widget _errorState() => Center(
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
                onPressed: () => ref.invalidate(productCatalogProvider),
                child: const Text('Retry')),
          ],
        ),
      );

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
