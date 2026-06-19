import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';

/// Bottom-nav scaffold wrapping Home / Collection / Cart / Profile.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = ['/home', '/collection', '/cart', '/profile'];

  int _indexFor(String location) {
    final i = _tabs.indexWhere((t) => location.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final cartCount = ref.watch(cartProvider).length;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (i) => context.go(_tabs[i]),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundColor: AppColors.surface,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
              label: 'Collection'),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon:
                  const Icon(Icons.shopping_bag, color: AppColors.primary),
              label: 'Cart'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile'),
        ],
      ),
    );
  }
}

/// Lightweight placeholder for tabs not yet built in the vertical slice.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('$title — coming next',
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
