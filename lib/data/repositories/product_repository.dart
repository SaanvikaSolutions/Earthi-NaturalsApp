import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_providers.dart';
import '../api/api_client.dart';
import '../models/product.dart';
import '../models/category.dart';

/// Loads products from the backend.
class ProductRepository {
  ProductRepository(this._api);
  final ApiClient _api;

  Future<List<Product>> fetchAll({
    String? category,
    String? subcategory,
    String? query,
  }) async {
    final data = await _api.get('/products', query: {
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (query != null) 'q': query,
    });
    return (data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> fetchById(String id) async {
    final data = await _api.get('/products/$id');
    return Product.fromJson(data as Map<String, dynamic>);
  }

  /// Categories with their subcategories.
  Future<List<Category>> fetchCategories() async {
    final data = await _api.get('/categories');
    return (data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);

/// The full product catalogue, loaded from the API.
final productCatalogProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).fetchAll();
});

/// Filter passed to [productsByCategoryProvider]. A null/empty [categoryId]
/// means "all products" (the Collection tile); a null [subcategoryId] means
/// "every subcategory in this category".
typedef ProductFilter = ({String? categoryId, String? subcategoryId});

/// Products for a given category (and optional subcategory), loaded from the
/// API. Keyed by the filter so each combination is cached independently.
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, ProductFilter>((ref, filter) {
  final categoryId =
      (filter.categoryId == null || filter.categoryId!.isEmpty)
          ? null
          : filter.categoryId;
  return ref.watch(productRepositoryProvider).fetchAll(
        category: categoryId,
        subcategory: filter.subcategoryId,
      );
});

/// All categories (with subcategories), loaded from the API.
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(productRepositoryProvider).fetchCategories();
});
