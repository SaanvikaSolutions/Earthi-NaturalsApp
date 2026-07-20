import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// Profile tab — account header plus a list of account / settings actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _items = <_MenuItem>[
    _MenuItem(Icons.shopping_bag_outlined, 'My Orders',
        'Track, return or buy again', '/orders'),
    _MenuItem(Icons.favorite_border, 'Wishlist', 'Your saved products',
        '/wishlist'),
    _MenuItem(Icons.location_on_outlined, 'Saved Addresses',
        'Manage delivery addresses', '/addresses'),
    _MenuItem(Icons.payment_outlined, 'Payment Methods',
        'Cards, UPI & wallets', '/payment-methods'),
    _MenuItem(Icons.notifications_none, 'Notifications', 'Offers & updates',
        '/notifications'),
    _MenuItem(Icons.help_outline, 'Help & Support', 'FAQs and contact us',
        '/help'),
    _MenuItem(Icons.info_outline, 'About Earthi Naturals', 'Our story',
        '/about'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Gap.pagePadding, 8, Gap.pagePadding, 24),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Profile',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: Gap.sm),
            _header(context, ref),
            const SizedBox(height: Gap.lg),
            ..._items.map((item) => _tile(context, item)),
            const SizedBox(height: Gap.lg),
            _logoutTile(context, ref),
            const SizedBox(height: Gap.md),
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

  Widget _header(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final name = user?.name ?? 'Guest';
    final subtitle = (user?.phone.isNotEmpty ?? false)
        ? user!.phone
        : (user?.email ?? 'Not signed in');
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(user?.initials ?? '?',
                style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/edit-profile'),
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, _MenuItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.chipBg,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 20, color: AppColors.primary),
          ),
          title: Text(item.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text(item.subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textMuted),
          onTap: () => context.push(item.route),
        ),
      );

  Widget _logoutTile(BuildContext context, WidgetRef ref) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.remove.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, size: 20, color: AppColors.remove),
        ),
        title: const Text('Logout',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.remove)),
        onTap: () async {
          await ref.read(authControllerProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
      );
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _MenuItem(this.icon, this.title, this.subtitle, this.route);
}
