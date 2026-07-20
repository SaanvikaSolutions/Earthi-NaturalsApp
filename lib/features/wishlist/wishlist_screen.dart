import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../home/product_card.dart';

/// Wishlist — the signed-in user's saved products, loaded from the API.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Wishlist'),
        actions: [
          CartIconButton(
            tooltip: 'Cart',
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: SafeArea(
        child: wishlist.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text("Couldn't load your wishlist",
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: () => ref.invalidate(wishlistProvider),
                    child: const Text('Retry')),
              ],
            ),
          ),
          data: (saved) {
            if (saved.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('Your wishlist is empty',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(wishlistProvider),
              child: GridView.builder(
                padding: const EdgeInsets.all(Gap.pagePadding),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                itemCount: saved.length,
                itemBuilder: (_, i) =>
                    ProductCard(product: saved[i], width: double.infinity),
              ),
            );
          },
        ),
      ),
    );
  }
}
