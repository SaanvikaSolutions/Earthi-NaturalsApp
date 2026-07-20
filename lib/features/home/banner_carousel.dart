import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../data/repositories/product_repository.dart';

/// A banner and the category its call-to-action promises.
class _Banner {
  final String image;

  /// Category name to open, matched against the backend's categories.
  /// Empty means the artwork doesn't point at one category — open everything.
  final String category;

  const _Banner(this.image, this.category);
}

/// Promotional banner carousel with seamless infinite auto-scroll and page
/// dots. Tapping a banner opens the section its artwork advertises.
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  // Kept in step with the artwork's own call to action: "Shop Baby" must land
  // on Baby, "All-natural skincare"/"Sun Protection" on Skin. The oils banner
  // says "View Combos", which isn't a category, so it opens the catalogue.
  static const _banners = <_Banner>[
    _Banner('assets/images/banner_glow.png', 'Skin'),
    _Banner('assets/images/banner_sun.png', 'Skin'),
    _Banner('assets/images/banner_oils.png', ''),
    _Banner('assets/images/banner_baby.png', 'Baby'),
  ];

  // Start in the middle of a very large virtual range so the user can scroll
  // forward/backward indefinitely without ever hitting an edge.
  static const _virtualCount = 100000;
  static final int _initialPage =
      (_virtualCount ~/ 2) - ((_virtualCount ~/ 2) % _banners.length);

  // Full-width viewport: one banner at a time, with no slice of the previous
  // or next slide showing and no horizontal squeeze on the artwork's text.
  late final PageController _controller =
      PageController(initialPage: _initialPage);
  Timer? _timer;
  int _page = _initialPage;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Horizontal inset applied to each side of a banner card.
  static const _cardInset = 6.0;

  @override
  Widget build(BuildContext context) {
    // Size the carousel from the card's own width (viewport minus the insets)
    // so the artwork keeps its native 375:156 ratio and BoxFit.cover has
    // nothing to crop — otherwise the banner text is clipped left and right.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth - _cardInset * 2;
        return Column(
          children: [
            SizedBox(
              height: cardWidth * 156 / 375,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _virtualCount,
                itemBuilder: (_, i) =>
                    _card(context, _banners[i % _banners.length]),
              ),
            ),
            const SizedBox(height: 12),
            _dots(),
          ],
        );
      },
    );
  }

  /// Opens the category the banner advertises, with its subcategory filters.
  /// Falls back to the catalogue if the category isn't loaded or was renamed
  /// server-side, so a tap always goes somewhere useful.
  void _openBanner(_Banner banner) {
    if (banner.category.isEmpty) {
      context.push('/all-products');
      return;
    }
    final categories =
        ref.read(categoriesProvider).asData?.value ?? const <Category>[];
    final match = categories.firstWhereOrNull(
        (c) => c.name.toLowerCase() == banner.category.toLowerCase());
    if (match == null) {
      context.push('/all-products', extra: banner.category);
      return;
    }
    context.push('/category', extra: match);
  }

  Widget _card(BuildContext context, _Banner banner) => GestureDetector(
        onTap: () => _openBanner(banner),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: _cardInset),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(banner.image, fit: BoxFit.cover),
        ),
      );

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_banners.length, (i) {
          final active = i == _page % _banners.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? AppColors.accentBlack : AppColors.inputBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
}
