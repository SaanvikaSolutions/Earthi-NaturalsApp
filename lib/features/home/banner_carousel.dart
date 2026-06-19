import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Auto-scrolling promotional banner carousel with page dots, showing the
/// pre-designed Figma hero banners.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const _banners = <_Banner>[
    _Banner(image: 'assets/images/banner_glow.png', route: '/collection'),
    _Banner(image: 'assets/images/banner_sun.png', route: '/collection'),
    _Banner(image: 'assets/images/banner_oils.png', route: '/collection'),
    _Banner(image: 'assets/images/banner_baby.png', route: '/collection'),
  ];

  final _controller = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(
        next,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 375 / 156,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) => _card(context, _banners[i]),
          ),
        ),
        const SizedBox(height: 12),
        _dots(),
      ],
    );
  }

  Widget _card(BuildContext context, _Banner b) => GestureDetector(
        onTap: () => context.go(b.route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(b.image, fit: BoxFit.cover),
        ),
      );

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_banners.length, (i) {
          final active = i == _page;
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

class _Banner {
  final String image;
  final String route;
  const _Banner({required this.image, required this.route});
}
