// Drives the Razorpay checkout wiring on a device.
//
// Deliberately stops short of a real payment: `server/.env` holds LIVE Razorpay
// keys and points at the production Atlas cluster, so completing a checkout
// would charge a card and write a real order row. Signed out, the backend
// rejects the request at the auth boundary — which still proves the button
// reaches POST /api/payments/order and that the failure is handled.
//
// Run with the backend up on :4000:
//   flutter test integration_test/payment_test.dart -d <device-id> \
//     --dart-define=SEED=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:earthi_naturals/core/theme/app_theme.dart';
import 'package:earthi_naturals/features/cart/cart_controller.dart';
import 'package:earthi_naturals/features/checkout/checkout_screen.dart';
import 'package:earthi_naturals/features/profile/addresses_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget home) => ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => home),
              GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
            ],
          ),
        ),
      );

  Future<void> settleFonts(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('Proceed to Pay calls the payments endpoint and surfaces 401',
      (tester) async {
    await tester.pumpWidget(app(const CheckoutScreen()));
    await settleFonts(tester);

    // Guard the premise: without a seeded cart the button is disabled and the
    // test would pass without ever making a request.
    final container = ProviderScope.containerOf(
        tester.element(find.byType(CheckoutScreen)));
    expect(container.read(cartProvider), isNotEmpty,
        reason: 'run with --dart-define=SEED=true');

    final button = find.text('Proceed to Pay');
    expect(button, findsOneWidget);
    await tester.tap(button);

    // Let the request go out and the snackbar land.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Signed out, the server rejects at auth — so we know the round trip
    // happened, and no order or Razorpay order was created.
    expect(find.text('Please sign in to place an order'), findsOneWidget);

    // The Razorpay sheet must not have opened, and the cart must survive a
    // failed start: nothing was paid, so nothing should be cleared.
    expect(find.text('Order placed!'), findsNothing);
    expect(container.read(cartProvider), isNotEmpty);
  });
}
