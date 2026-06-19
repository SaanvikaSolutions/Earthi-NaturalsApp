import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../data/mock/mock_data.dart';
import 'banner_carousel.dart';
import 'product_card.dart';
import 'testimonial_marquee.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _topBar(context)),
            SliverToBoxAdapter(child: _categoryMenu(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: BannerCarousel()),
            _sectionHeader('Our best sellers'),
            SliverToBoxAdapter(child: _horizontalProducts(MockData.bestSellers)),
            _sectionHeader('Shop by concerns'),
            SliverToBoxAdapter(child: _concerns()),
            _sectionHeader('Just Dropped'),
            SliverToBoxAdapter(child: _horizontalProducts(MockData.justDropped)),
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
            _sectionHeader('Everyday glow'),
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
                      product: MockData.products[i], width: double.infinity),
                  childCount: MockData.products.length,
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
            SliverToBoxAdapter(
                child: _horizontalProducts(
                    MockData.products.where((p) => p.category == 'Hair care').toList())),
            SliverToBoxAdapter(child: _viewAllButton(context)),
            // Baby — baby-care carousel (reusing the catalogue as mock).
            _plainHeader('Baby'),
            SliverToBoxAdapter(child: _horizontalProducts(MockData.bestSellers)),
            SliverToBoxAdapter(child: _viewAllButton(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
            onPressed: () => context.go('/collection'),
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
        padding: const EdgeInsets.fromLTRB(Gap.pagePadding, 4, 8, 8),
        child: Row(
          children: [
            const BrandLogo(width: 120),
            const Spacer(),
            IconButton(
                onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none)),
            IconButton(
                onPressed: () => context.push('/wishlist'),
                icon: const Icon(Icons.favorite_border)),
          ],
        ),
      );

  // Horizontal category tiles (Collection / Skin Care / Hair Care / ...).
  Widget _categoryMenu(BuildContext context) {
    const cats = <_Category>[
      _Category('Collection', 'assets/images/cat_collection.png'),
      _Category('Skin Care', 'assets/images/cat_skin.png'),
      _Category('Hair Care', 'assets/images/cat_hair.png'),
      _Category('Body Care', 'assets/images/cat_body.png'),
      _Category('Baby Care', 'assets/images/cat_baby.png'),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final c = cats[i];
          return GestureDetector(
            onTap: () => context.push('/category', extra: c.label),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    c.image,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 84,
                  child: Text(c.label,
                      textAlign: TextAlign.center,
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

  SliverToBoxAdapter _sectionHeader(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Gap.pagePadding, 24, Gap.pagePadding, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const Text('View all',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.primary)),
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

class _Category {
  final String label;
  final String image;
  const _Category(this.label, this.image);
}

