// Drives the real app on a device to observe the bug-fix behaviours end to end.
// Run with:
//   flutter test integration_test/app_test.dart -d <device-id>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:earthi_naturals/core/theme/app_theme.dart';
import 'package:earthi_naturals/data/mock/mock_data.dart';
import 'package:earthi_naturals/features/cart/cart_controller.dart';
import 'package:earthi_naturals/features/cart/cart_screen.dart';
import 'package:earthi_naturals/features/checkout/checkout_screen.dart';
import 'package:earthi_naturals/features/product/product_screen.dart';
import 'package:earthi_naturals/features/profile/addresses_screen.dart';
import 'package:earthi_naturals/features/profile/help_support_screen.dart';
import 'package:earthi_naturals/features/profile/payment_methods_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Hosts [home] behind a real GoRouter using the app's own paths, so
  /// `context.push('/checkout')` resolves exactly as it does in the app.
  Widget app(Widget home) => ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => home),
              GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
              GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
              GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
            ],
          ),
        ),
      );

  /// Text metrics change when the Google font finishes loading, which reflows
  /// the page. Let that land before measuring anything.
  Future<void> settleFonts(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('size chips keep a fixed layout when a size is selected',
      (tester) async {
    // Pin a 375pt-wide surface: the width the design targets, and narrow
    // enough that the four size chips wrap 3 + 1 as reported.
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final product = MockData.products.first;
    await tester.pumpWidget(app(ProductScreen(product: product)));
    await settleFonts(tester);

    final sizes = product.sizes;
    // The page is a lazy ListView — bring the Sizes block on screen so the
    // chips are actually built before measuring them.
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, sizes.last),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    Map<String, Rect> snap() => {
          for (final s in sizes)
            s: tester.getRect(find.widgetWithText(ChoiceChip, s)),
        };

    final before = snap();
    // Row layout the user sees before touching anything.
    final rowsBefore = before.values.map((r) => r.top).toSet().length;

    // Select the last size — the one that sits on the second row.
    await tester.tap(find.widgetWithText(ChoiceChip, sizes.last));
    await tester.pumpAndSettle();
    final after = snap();
    final rowsAfter = after.values.map((r) => r.top).toSet().length;

    expect(rowsAfter, rowsBefore,
        reason: 'chips reflowed onto a different number of rows: '
            '$rowsBefore -> $rowsAfter');
    for (final s in sizes) {
      expect(after[s], before[s],
          reason: 'chip "$s" moved/resized on selection: '
              '${before[s]} -> ${after[s]}');
    }
  });

  testWidgets('Buy Now opens checkout, not the cart', (tester) async {
    await tester.pumpWidget(app(ProductScreen(product: MockData.products.first)));
    await settleFonts(tester);

    await tester.tap(find.text('Buy Now'));
    await tester.pumpAndSettle();

    // Checkout's app bar title, and definitely not the cart's.
    expect(find.text('Select Address & Pay'), findsOneWidget);
    expect(find.textContaining('Cart ('), findsNothing);
  });

  testWidgets('checkout Change Address opens Saved Addresses', (tester) async {
    await tester.pumpWidget(app(const CheckoutScreen()));
    await settleFonts(tester);

    await tester.tap(find.text('Change or Edit Address'));
    await tester.pumpAndSettle();

    expect(find.text('Saved Addresses'), findsOneWidget);
  });

  testWidgets('checkout shows the address picked on Saved Addresses',
      (tester) async {
    await tester.pumpWidget(app(const CheckoutScreen()));
    await settleFonts(tester);
    // Seeded default is the Home address.
    expect(find.textContaining('560001'), findsWidgets);

    await tester.tap(find.text('Change or Edit Address'));
    await tester.pumpAndSettle();
    // Pick the Work address, then go back to checkout.
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('560066'), findsWidgets);
  });

  testWidgets('addresses: add, edit and delete', (tester) async {
    await tester.pumpWidget(app(const AddressesScreen()));
    await settleFonts(tester);
    expect(find.text('Home'), findsOneWidget);

    // --- Add ---
    await tester.tap(find.text('Add New Address'));
    await tester.pumpAndSettle();

    // Empty submit must be rejected by the validator.
    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();
    expect(find.text('Full name is required'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'), 'Asha Rao');
    await tester.enterText(find.widgetWithText(TextFormField, 'Address'),
        '9 Palm Grove, Indiranagar, Bengaluru, Karnataka 560038');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone number'), '+91 90000 11111');
    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();

    expect(find.text('Asha Rao'), findsOneWidget);

    // --- Edit --- (the new card is last; rename it)
    await tester.tap(find.byTooltip('Edit address').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit Address'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'), 'Asha R Rao');
    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();
    expect(find.text('Asha R Rao'), findsOneWidget);
    expect(find.text('Asha Rao'), findsNothing);

    // --- Delete --- (confirm dialog, then gone)
    await tester.tap(find.byTooltip('Delete address').last);
    await tester.pumpAndSettle();
    expect(find.text('Delete address?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Asha R Rao'), findsNothing);
  });

  testWidgets('payment methods: add card with validation', (tester) async {
    await tester.pumpWidget(app(const PaymentMethodsScreen()));
    await settleFonts(tester);

    await tester.tap(find.text('Add Payment Method'));
    await tester.pumpAndSettle();

    // Garbage input is rejected.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Card number'), '123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Expiry (MM/YY)'), '13/20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid card number'), findsOneWidget);
    expect(find.text('Use MM/YY'), findsOneWidget);

    // A real-looking Visa saves, masked to the last four digits.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Card number'), '4111111111111111');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Expiry (MM/YY)'), '09/30');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Visa •••• 1111'), findsOneWidget);
    // The full card number must never be rendered.
    expect(find.textContaining('4111111111111111'), findsNothing);
  });

  testWidgets('removing the last cart item shows the empty state, not a crash',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(cartProvider.notifier)
        .add(MockData.products.first, MockData.products.first.sizes.first);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
        ]),
      ),
    ));
    await settleFonts(tester);
    expect(find.text('Cart (01)'), findsOneWidget);

    // Tap the line's remove (x), then confirm Remove in the dialog.
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Cart (00)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('help & support shows Call/Email and no Live Chat',
      (tester) async {
    await tester.pumpWidget(app(const HelpSupportScreen()));
    await settleFonts(tester);

    expect(find.text('Call Us'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Live Chat'), findsNothing);
  });
}
