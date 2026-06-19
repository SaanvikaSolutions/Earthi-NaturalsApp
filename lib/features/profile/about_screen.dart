import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';

/// About Earthi Naturals — brand story and values.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _values = <List<dynamic>>[
    [Icons.eco_outlined, '100% Natural', 'Free from harmful chemicals'],
    [Icons.spa_outlined, 'Ayurvedic Roots', 'Time-honoured ingredients'],
    [Icons.pets_outlined, 'Cruelty Free', 'Never tested on animals'],
    [Icons.recycling_outlined, 'Eco Packaging', 'Recyclable and mindful'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.pagePadding),
          children: [
            const SizedBox(height: Gap.md),
            const Center(child: BrandLogo(width: 200)),
            const SizedBox(height: Gap.xl),
            const Text('Our Story',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.sm),
            const Text(
              'Earthi Naturals was born from a simple belief — that nature holds '
              'the answers to healthy skin and hair. We blend time-honoured '
              'Ayurvedic wisdom with modern care to create products that are '
              'pure, effective and deeply nourishing.\n\n'
              'Every formulation is crafted with responsibly sourced herbs and '
              'oils, free from harmful chemicals, so you can care for yourself '
              'the way nature intended.',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textMuted, height: 1.6),
            ),
            const SizedBox(height: Gap.xl),
            const Text('What we stand for',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: _values
                  .map((v) => _valueCard(
                      v[0] as IconData, v[1] as String, v[2] as String))
                  .toList(),
            ),
            const SizedBox(height: Gap.xl),
            const Center(
              child: Text('Tradition · Touch · Transformation',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: Gap.sm),
            const Center(
              child: Text('Version 1.0.0',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueCard(IconData icon, String title, String subtitle) =>
      Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: AppColors.chipBg,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );
}
