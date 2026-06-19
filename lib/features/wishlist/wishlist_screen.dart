import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock/mock_data.dart';
import '../home/product_card.dart';

/// Wishlist — saved products shown in a 2-column grid.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock: treat a few catalogue items as saved.
    final saved = [
      MockData.products[0],
      MockData.products[2],
      MockData.products[3],
      MockData.products[5],
    ];
    return Scaffold(
      appBar:
          AppBar(leading: const BackButton(), title: const Text('Wishlist')),
      body: SafeArea(
        child: saved.isEmpty
            ? const Center(
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
              )
            : GridView.builder(
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
      ),
    );
  }
}
