import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';

/// Saved Addresses — list of delivery addresses with add/edit actions.
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  static const _addresses = <_Address>[
    _Address('Home', 'Rishika Patel',
        '12 Lotus Residency, MG Road, Bengaluru, Karnataka 560001',
        '+91 98765 43210', true),
    _Address('Work', 'Rishika Patel',
        '4th Floor, Tech Park, Whitefield, Bengaluru, Karnataka 560066',
        '+91 98765 43210', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Saved Addresses')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(Gap.pagePadding),
                itemCount: _addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
                itemBuilder: (_, i) => _card(_addresses[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.pagePadding),
              child: PrimaryButton(
                label: 'Add New Address',
                icon: Icons.add,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_Address a) => Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.chipBg,
                    borderRadius: BorderRadius.circular(Radii.badge),
                  ),
                  child: Text(a.label,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                if (a.isDefault) ...[
                  const SizedBox(width: 8),
                  const Text('Default',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
                const Spacer(),
                Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 14),
                Icon(Icons.delete_outline,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Text(a.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(a.address,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted, height: 1.4)),
            const SizedBox(height: 6),
            Text(a.phone,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );
}

class _Address {
  final String label;
  final String name;
  final String address;
  final String phone;
  final bool isDefault;
  const _Address(
      this.label, this.name, this.address, this.phone, this.isDefault);
}
