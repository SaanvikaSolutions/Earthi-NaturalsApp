import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';

/// Payment Methods — saved cards, UPI and wallets.
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  static const _methods = <_Method>[
    _Method(Icons.credit_card, 'Visa •••• 4242', 'Expires 08/27', true),
    _Method(Icons.account_balance_wallet_outlined, 'UPI — rishika@okhdfc',
        'Linked', false),
    _Method(Icons.credit_card, 'Mastercard •••• 8810', 'Expires 11/26', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Payment Methods')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(Gap.pagePadding),
                itemCount: _methods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _card(_methods[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.pagePadding),
              child: PrimaryButton(
                label: 'Add Payment Method',
                icon: Icons.add,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_Method m) => Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.chipBg,
                shape: BoxShape.circle,
              ),
              child: Icon(m.icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(m.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (m.isDefault)
              const Text('Default',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600))
            else
              const Icon(Icons.more_vert,
                  size: 20, color: AppColors.textMuted),
          ],
        ),
      );
}

class _Method {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDefault;
  const _Method(this.icon, this.title, this.subtitle, this.isDefault);
}
