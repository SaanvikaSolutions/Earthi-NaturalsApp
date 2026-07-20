import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../data/repositories/product_repository.dart';
import 'banner_carousel.dart';
import 'product_card.dart';
import 'testimonial_marquee.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Products come from the backend API. While the request is in flight (or if
    // the device is offline) we fall back to the bundled mock catalogue so the
    // layout never breaks.
    final catalog = ref.watch(productCatalogProvider);
    final List<Product> products = catalog.asData?.value ?? MockData.products;
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <Category>[];
    final bestSellers = products.take(4).toList();
    final justDropped = products.reversed.take(4).toList();
    final hairCare =
        products.length > 6 ? products.sublist(2, 6) : products;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header — stays pinned while the rest scrolls.
            _topBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(productCatalogProvider.future),
                child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _categoryMenu(context, categories)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: BannerCarousel()),
            _sectionHeader(context, 'Our best sellers'),
            SliverToBoxAdapter(child: _horizontalProducts(bestSellers)),
            _sectionHeader(context, 'Shop by concerns'),
            SliverToBoxAdapter(child: _concerns()),
            _sectionHeader(context, 'Just Dropped'),
            SliverToBoxAdapter(child: _horizontalProducts(justDropped)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/banner_ayurvedic.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            _sectionHeader(context, 'Everyday glow'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  Gap.pagePadding, 0, Gap.pagePadding, 24),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ProductCard(
                      product: products[i], width: double.infinity),
                  childCount: products.length,
                ),
              ),
            ),
            // Real stories, Real results — customer testimonials.
            _testimonialsHeader(),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: TestimonialMarquee(),
              ),
            ),
            // Gentle hair love — hair-care carousel.
            _plainHeader('Gentle hair love'),
            SliverToBoxAdapter(child: _horizontalProducts(hairCare)),
            SliverToBoxAdapter(child: _viewAllButton(context)),
            // Baby — baby-care carousel (reusing the catalogue as mock).
            _plainHeader('Baby'),
            SliverToBoxAdapter(child: _horizontalProducts(bestSellers)),
            SliverToBoxAdapter(child: _viewAllButton(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Heading + intro paragraph for the testimonials block.
  SliverToBoxAdapter _testimonialsHeader() => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              Gap.pagePadding, 28, Gap.pagePadding, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Real stories, Real results',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Text(
                'Our products gently care for your skin and are made with '
                'natural, eco-friendly ingredients so they\'re just as kind '
                'to the Earth as they are to you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      );

  SliverToBoxAdapter _plainHeader(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Gap.pagePadding, 28, Gap.pagePadding, 12),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _viewAllButton(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Center(
          child: OutlinedButton(
            onPressed: () => context.push('/all-products'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.inputBorder),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.pill)),
            ),
            child: const Text('View All',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ),
      );

  Widget _topBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Gap.pagePadding, 0, 8, 4),
        child: Row(
          children: [
            const BrandLogo(width: 120),
            const Spacer(),
            IconButton(
                onPressed: () => context.push('/all-products'),
                icon: const Icon(Icons.search)),
            IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_none)),
            WishlistIconButton(
                onPressed: () => context.push('/wishlist')),
          ],
        ),
      );

  // Maps a real category name (Skin / Hair / Body / Baby) to a tile image,
  // falling back to the generic collection art for anything unrecognised.
  static String _categoryImage(String name) {
    final n = name.toLowerCase();
    if (n.contains('skin')) return 'assets/images/cat_skin.png';
    if (n.contains('hair')) return 'assets/images/cat_hair.png';
    if (n.contains('baby')) return 'assets/images/cat_baby.png';
    if (n.contains('body')) return 'assets/images/cat_body.png';
    return 'assets/images/cat_collection.png';
  }

  // Horizontal category tiles: a "Collection" (all) tile followed by the real
  // categories loaded from the backend.
  Widget _categoryMenu(BuildContext context, List<Category> categories) {
    // (label, image, category) — null category == Collection / all.
    final tiles = <(String, String, Category?)>[
      ('Collection', 'assets/images/cat_collection.png', null),
      for (final c in categories) (c.name, _categoryImage(c.name), c),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final (label, image, category) = tiles[i];
          return GestureDetector(
            onTap: () => context.push('/category', extra: category),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    image,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 84,
                  child: Text(label,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext context, String title) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Gap.pagePadding, 24, Gap.pagePadding, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => context.push('/all-products'),
                child: const Text('View all',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );

  Widget _horizontalProducts(List products) => SizedBox(
        height: 280,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => ProductCard(product: products[i]),
        ),
      );

  Widget _concerns() => SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
          itemCount: MockData.concerns.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  MockData.concernIcons[i],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 120,
                child: Text(MockData.concerns[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
}

