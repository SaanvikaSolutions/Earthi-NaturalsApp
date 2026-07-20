import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_providers.dart';
import '../api/api_client.dart';
import '../models/product.dart';

/// Manages the signed-in user's wishlist (requires a bearer token).
class WishlistRepository {
  WishlistRepository(this._api);
  final ApiClient _api;

  /// Full product objects for the user's saved slugs.
  Future<List<Product>> fetchAll() async {
    final data = await _api.get('/wishlist');
    return (data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(String slug) => _api.post('/wishlist/$slug', const {});

  Future<void> remove(String slug) => _api.delete('/wishlist/$slug');
}

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(ref.watch(apiClientProvider)),
);

/// The signed-in user's saved products, loaded from the API.
final wishlistProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(wishlistRepositoryProvider).fetchAll(),
);

/// Number of products in the wishlist (0 while loading or on error).
/// Used for icon badges across the app.
final wishlistCountProvider = Provider<int>(
  (ref) => ref.watch(wishlistProvider).asData?.value.length ?? 0,
);
