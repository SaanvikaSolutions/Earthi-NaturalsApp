import 'package:go_router/go_router.dart';
import '../../data/models/product.dart';
import '../../data/mock/mock_data.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/collection/collection_screen.dart';
import '../../features/collection/all_products_screen.dart';
import '../../features/collection/collection_list_screen.dart';
import '../../features/collection/category_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/profile/payment_methods_screen.dart';
import '../../features/profile/notifications_screen.dart';
import '../../features/profile/help_support_screen.dart';
import '../../features/profile/about_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/product/product_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/shell/app_shell.dart';

/// Debug-only start route override (e.g. --dart-define=START=/home) so each
/// screen can be screenshotted in isolation. Defaults to the real entry point.
const _startRoute = String.fromEnvironment('START', defaultValue: '/splash');

final appRouter = GoRouter(
  initialLocation: _startRoute,
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(
      path: '/product',
      builder: (_, state) => ProductScreen(
        product: (state.extra as Product?) ?? MockData.products.first,
      ),
    ),
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
    GoRoute(
      path: '/all-products',
      builder: (_, state) => AllProductsScreen(
        initialCategory: (state.extra as String?) ?? 'All',
      ),
    ),
    GoRoute(
      path: '/collection-list',
      builder: (_, state) => CollectionListScreen(
        kind: (state.extra as CollectionKind?) ?? CollectionKind.newArrival,
      ),
    ),
    GoRoute(
      path: '/category',
      builder: (_, state) =>
          CategoryScreen(category: (state.extra as String?) ?? 'Collection'),
    ),
    GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
    GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
    GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
    GoRoute(
        path: '/payment-methods',
        builder: (_, __) => const PaymentMethodsScreen()),
    GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/help', builder: (_, __) => const HelpSupportScreen()),
    GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
    // Bottom-nav tabs live inside the shell.
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
            path: '/collection',
            builder: (_, __) => const CollectionScreen()),
        GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        GoRoute(
            path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
