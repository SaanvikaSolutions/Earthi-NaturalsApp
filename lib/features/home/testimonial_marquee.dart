import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A seamless, continuously-scrolling row of testimonial cards.
/// The card set repeats endlessly and the scroll offset wraps by one set
/// width, so the loop has no visible seam.
class TestimonialMarquee extends StatefulWidget {
  const TestimonialMarquee({super.key});

  @override
  State<TestimonialMarquee> createState() => _TestimonialMarqueeState();
}

class _TestimonialMarqueeState extends State<TestimonialMarquee>
    with SingleTickerProviderStateMixin {
  static const _cards = <String>[
    'assets/images/testimonial_1.png',
    'assets/images/testimonial_2.png',
    'assets/images/testimonial_3.png',
  ];
  static const double _cardW = 274;
  static const double _cardH = 150;
  static const double _gap = 12;
  static const double _speed = 35; // pixels per second

  final _scroll = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_scroll.hasClients) return;
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    final setWidth = (_cardW + _gap) * _cards.length;
    var next = _scroll.offset + _speed * dt;
    if (next >= setWidth) next -= setWidth;
    _scroll.jumpTo(next);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardH,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: _gap),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              _cards[i % _cards.length],
              width: _cardW,
              height: _cardH,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
