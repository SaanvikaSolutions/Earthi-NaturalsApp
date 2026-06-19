import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Help & Support — contact options plus an FAQ accordion.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = <List<String>>[
    [
      'How long does delivery take?',
      'Orders are usually delivered within 3–5 business days. You can track '
          'live status from My Orders.'
    ],
    [
      'What is your return policy?',
      'Unopened products can be returned within 7 days of delivery for a full '
          'refund or exchange.'
    ],
    [
      'Are the products natural?',
      'Yes — every Earthi Naturals product is free from harmful chemicals and '
          'made with Ayurvedic ingredients.'
    ],
    [
      'How do I cancel an order?',
      'You can cancel any order before it is shipped from the My Orders screen.'
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.pagePadding),
          children: [
            Row(
              children: [
                Expanded(
                    child: _contact(Icons.chat_bubble_outline, 'Live Chat')),
                const SizedBox(width: 12),
                Expanded(child: _contact(Icons.call_outlined, 'Call Us')),
                const SizedBox(width: 12),
                Expanded(child: _contact(Icons.mail_outline, 'Email')),
              ],
            ),
            const SizedBox(height: Gap.xl),
            const Text('Frequently asked questions',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.sm),
            ..._faqs.map((f) => Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding:
                        const EdgeInsets.only(bottom: 12, right: 24),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.textMuted,
                    title: Text(f[0],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(f[1],
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.5)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _contact(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: Gap.md),
        decoration: BoxDecoration(
          color: AppColors.chipBg,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
