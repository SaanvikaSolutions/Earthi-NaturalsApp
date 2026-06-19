import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class _Slide {
  final String title;
  final String body;
  final Color bg;
  final String image;
  const _Slide(this.title, this.body, this.bg, this.image);
}

const _slides = <_Slide>[
  _Slide(
    'Made with Plant Based Love',
    'Our journey began with a promise to care using only the purest, most honest ingredients.',
    Color(0xFFD7E0C0),
    'assets/images/onboard_1.png',
  ),
  _Slide(
    'Clean Gentle Real Skincare',
    'Safe for every skin type. Powered by time-tested botanicals, not chemicals.',
    Color(0xFFD9BE97),
    'assets/images/onboard_2.png',
  ),
  _Slide(
    'Crafted for You & the Earth',
    'From our hands to your home, sustainably crafted with care for you and the planet.',
    Color(0xFFF4EEE0),
    'assets/images/onboard_3.png',
  ),
];

/// Auto-advancing, swipeable onboarding carousel with story-style progress bars.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pc = PageController();
  late final AnimationController _ac;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance(auto: true);
      });
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    _pc.dispose();
    super.dispose();
  }

  void _advance({bool auto = false}) {
    if (_page < _slides.length - 1) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _ac.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: slide.bg,
        child: SafeArea(
          child: Column(
            children: [
              // Story-style segmented progress
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: AnimatedBuilder(
                  animation: _ac,
                  builder: (_, __) => Row(
                    children: List.generate(_slides.length, (i) {
                      double fill;
                      if (i < _page) {
                        fill = 1;
                      } else if (i == _page) {
                        fill = _ac.value;
                      } else {
                        fill = 0;
                      }
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: i < _slides.length - 1 ? 6 : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fill,
                              minHeight: 4,
                              backgroundColor: Colors.black.withValues(alpha: 0.15),
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Swipeable pages
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              // Next button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _advance(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlack,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _page == _slides.length - 1 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Illustration from Figma.
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(slide.image, fit: BoxFit.cover),
            ),
          ),
          const Spacer(flex: 1),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
