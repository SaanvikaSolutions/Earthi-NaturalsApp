// Drives the second round of reported fixes on a real device.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:earthi_naturals/core/theme/app_theme.dart';
import 'package:earthi_naturals/data/mock/mock_data.dart';
import 'package:earthi_naturals/features/cart/cart_controller.dart';
import 'package:earthi_naturals/features/cart/cart_screen.dart';
import 'package:earthi_naturals/features/profile/help_support_screen.dart';
import 'package:earthi_naturals/features/profile/payment_methods_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settleFonts(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Widget app(Widget home, {ProviderContainer? container}) {
    final child = MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/wishlist', builder: (_, __) => const Scaffold()),
      ]),
    );
    return container == null
        ? ProviderScope(child: child)
        : UncontrolledProviderScope(container: container, child: child);
  }

  testWidgets('card expiry auto-inserts the slash and accepts a typed one',
      (tester) async {
    await tester.pumpWidget(app(const PaymentMethodsScreen()));
    await settleFonts(tester);
    await tester.tap(find.text('Add Payment Method'));
    await tester.pumpAndSettle();

    final expiry = find.widgetWithText(TextFormField, 'Expiry (MM/YY)');

    // Typing digits alone produces the separator.
    await tester.enterText(expiry, '09');
    await tester.pumpAndSettle();
    expect(find.text('09/'), findsOneWidget);

    await tester.enterText(expiry, '0930');
    await tester.pumpAndSettle();
    expect(find.text('09/30'), findsOneWidget);

    // A single-digit month >1 is padded: "3" -> "03/".
    await tester.enterText(expiry, '3');
    await tester.pumpAndSettle();
    expect(find.text('03/'), findsOneWidget);

    // Typing the slash manually must not be swallowed or duplicated.
    await tester.enterText(expiry, '09/30');
    await tester.pumpAndSettle();
    expect(find.text('09/30'), findsOneWidget);

    // And it still saves.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Card number'), '4111111111111111');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Visa •••• 1111'), findsOneWidget);
  });

  testWidgets('opening an FAQ closes the one already open', (tester) async {
    await tester.pumpWidget(app(const HelpSupportScreen()));
    await settleFonts(tester);

    const a = 'How long does delivery take?';
    const b = 'What is your return policy?';
    const answerA =
        'Orders are usually delivered within 3–5 business days. You can track '
        'live status from My Orders.';

    await tester.tap(find.text(a));
    await tester.pumpAndSettle();
    expect(find.text(answerA), findsOneWidget);

    // Opening the second must collapse the first.
    await tester.tap(find.text(b));
    await tester.pumpAndSettle();
    expect(find.text(answerA), findsNothing);
    expect(find.textContaining('Unopened products can be returned'),
        findsOneWidget);
  });

  testWidgets('cart size selector lists other sizes and switches',
      (tester) async {
    final product = MockData.products.first;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).add(product, product.sizes.first);

    await tester.pumpWidget(app(const CartScreen(), container: container));
    await settleFonts(tester);
    expect(find.text(product.sizes.first), findsOneWidget);

    // Open the size pill — every size for this product should be offered.
    await tester.tap(find.byTooltip('Change size'));
    await tester.pumpAndSettle();
    for (final s in product.sizes) {
      expect(find.text(s), findsWidgets, reason: 'size $s missing from menu');
    }

    await tester.tap(find.text(product.sizes.last).last);
    await tester.pumpAndSettle();

    expect(container.read(cartProvider).single.size, product.sizes.last);
  });

  testWidgets('switching to a size already in the cart merges the lines',
      (tester) async {
    final product = MockData.products.first;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);
    cart.add(product, product.sizes.first, qty: 2);
    cart.add(product, product.sizes.last, qty: 1);

    await tester.pumpWidget(app(const CartScreen(), container: container));
    await settleFonts(tester);
    expect(container.read(cartProvider).length, 2);

    // Switch the first line onto the second line's size.
    await tester.tap(find.byTooltip('Change size').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(product.sizes.last).last);
    await tester.pumpAndSettle();

    final items = container.read(cartProvider);
    expect(items.length, 1, reason: 'duplicate line left behind');
    expect(items.single.qty, 3, reason: 'quantities should add up');
  });
}
